# ArtAgents — Änderungsprotokoll (llama.cpp Migration)

Datum: 2026-05-28  
Ziel: ArtAgents von Ollama-API auf llama.cpp `/completion`-Endpunkt umstellen + Workflow-Qualität verbessern.

---

## Geänderte Dateien

### 1. `settings.json`

**Geändert:**
- `"api_type"` hinzugefügt: `"llama_cpp"`
- `"ollama_url"` geändert: `"http://localhost:11434/api/generate"` → `"http://localhost:8080/completion"`

**Zurückrollen:**
```json
{
    "ollama_url": "http://localhost:11434/api/generate"
}
```
`"api_type"` komplett entfernen (Zeile löschen).

---

### 2. `agents/ollama_agent.py`

**Geändert:** Komplette Neufassung der `get_llm_response`-Funktion.

Kernänderungen:
- Liest `api_type` aus `settings`
- Bei `api_type == "llama_cpp"`:
  - Payload ohne `"model"`-Feld, ohne `"options"`-Wrapper
  - Parameter-Mapping: `num_predict → n_predict`, `penalize_newline → penalize_nl` usw.
  - SSE-Prefix stripping: `chunk[6:]` wenn Chunk mit `"data: "` beginnt
  - Stream-Ende: `stop: true` statt `done: true`
  - Leere Chunks und `[DONE]` werden übersprungen
- Bei `api_type == "ollama"`: Original-Logik unverändert

**Zurückrollen:** Original-Datei wiederherstellen (siehe unten).

<details>
<summary>Original get_llm_response (Ollama-only, zum Wiederherstellen)</summary>

```python
# ArtAgent/agents/ollama_agent.py

import json
import requests
from PIL import Image
import io
import base64
import numpy as np

def get_llm_response(
    role, prompt, model, settings, roles_data,
    images=None, max_tokens=1500, ollama_api_options=None
    ):
    ollama_url = settings.get("ollama_url", "http://localhost:11434/api/generate")
    ollama_api_prompt_to_console = settings.get("ollama_api_prompt_to_console", True)

    effective_options = settings.get("ollama_api_options", {}).copy()
    role_settings = roles_data.get(role, {}).get("ollama_api_options", {})
    effective_options.update(role_settings)
    if ollama_api_options:
        effective_options.update(ollama_api_options)
    if "num_predict" not in effective_options:
        effective_options["num_predict"] = max_tokens

    payload = {
        "model": model,
        "prompt": prompt,
        "stream": True,
        "options": effective_options
    }

    if images:
        image_data = []
        for i, img_object in enumerate(images):
            if isinstance(img_object, Image.Image):
                buffered = io.BytesIO()
                save_format = "JPEG" if img_object.mode != "RGBA" else "PNG"
                img_object.save(buffered, format=save_format)
                img_str = base64.b64encode(buffered.getvalue()).decode('utf-8')
                image_data.append(img_str)
        if image_data:
            payload["images"] = image_data

    llm_response = ""
    try:
        response = requests.post(ollama_url, json=payload, stream=True, timeout=180)
        response.raise_for_status()
        complete_response = ""
        stream_error_occurred = False
        for chunk in response.iter_lines(decode_unicode=True):
            if chunk:
                try:
                    chunk_data = json.loads(chunk)
                    complete_response += chunk_data.get('response', '')
                    if chunk_data.get('done'):
                        break
                except json.JSONDecodeError as e:
                    llm_response = f"⚠️ Error: Error decoding JSON stream. Details: {e}"
                    stream_error_occurred = True
                    break
        if not stream_error_occurred:
            llm_response = complete_response if complete_response else "No response text received."
    except requests.exceptions.RequestException as e:
        llm_response = f"⚠️ Error communicating with Ollama: {e}"

    return llm_response
```
</details>

---

### 3. `core/ollama_manager.py`

**Geändert:**
- `release_model(model_name, ollama_api_url, api_type="ollama")` — neuer Parameter `api_type`
- Bei `api_type == "llama_cpp"`: Funktion gibt sofort zurück (kein Release-Endpunkt in llama.cpp)
- `release_all_models_logic`: prüft ebenfalls `api_type`, überspringt bei llama.cpp

**Zurückrollen:**
```python
def release_model(model_name: str, ollama_api_url: str):
    # api_type-Parameter entfernen
    # if api_type == "llama_cpp": Block entfernen
```

---

### 4. `core/app_logic.py`

**Geändert:** Eine Zeile (~Zeile 225), Aufruf von `release_model`:

```python
# Vorher:
ollama_manager.release_model(selected_model_tracker_value, current_settings.get("ollama_url"))

# Nachher:
ollama_manager.release_model(selected_model_tracker_value, current_settings.get("ollama_url"), current_settings.get("api_type", "ollama"))
```

**Zurückrollen:** Dritter Parameter `, current_settings.get("api_type", "ollama")` entfernen.

---

### 5. `core/agent_manager.py`

**Geändert:** Zwei Stellen.

**Zeile ~62** — `if single_image_input:` → robustere Prüfung:
```python
# Vorher:
if single_image_input:

# Nachher:
if single_image_input is not None and not isinstance(single_image_input, (list, tuple)):
```

**Zeile ~96** — `step_prompt` Konstruktion vereinfacht:
```python
# Vorher:
role_desc = role_info.get("description", "Perform your function.")
step_prompt = f"Context:\n{current_context}\n---\nYour Role: {step_role} - {role_desc}\nYour Goal for this step: {step_goal}\n\nBased *only* on the provided context and your goal, provide your specific output:"

# Nachher:
role_desc = role_info.get("description", "You are a creative assistant. Write a detailed, descriptive output based on the task and context provided.")
step_prompt = (
    f"{role_desc}\n\n"
    f"Task: {step_goal}\n\n"
    f"Context:\n{current_context}\n"
    f"Write your output as plain descriptive text. "
    f"Do not write headers, placeholder markers like [Your Output], template structures, or any commentary about the process itself:"
)
```

---

### 6. `agents/custom_agent_roles.json`

**Geändert:** Neue Rollen hinzugefügt, bestehende verbessert.

Neu hinzugefügt:
- `"Universal Prompter"` — fehlte komplett, führte zu Fallback `"Perform your function."`
- `"Concise Describer"` — neu mit expliziter Kurzformat-Anweisung

Verbessert:
- `"Prompt Synthesizer"` — Beschreibung präzisiert, Platzhalter-Verbote ergänzt

**Zurückrollen:** `"Universal Prompter"` und `"Concise Describer"` Einträge entfernen. `"Prompt Synthesizer"` auf Original zurücksetzen:
```json
"Prompt Synthesizer": {
    "description": "Your sole task is to synthesize the information provided in the context from previous steps into a single, coherent, and effective final output (e.g., an image generation prompt or a summary). Focus on clear structure, integration of details, and fulfilling the overall workflow goal described in the context. Do not add commentary about the process.",
    "ollama_api_options": {
        "temperature": 0.6,
        "top_k": 40,
        "num_predict": 1024
    }
}
```

---

## Schnell-Rollback: zurück zu Ollama

1. `settings.json`: `"api_type"` entfernen, URL auf `http://localhost:11434/api/generate` zurücksetzen
2. `agents/ollama_agent.py`: Alle `api_type`-Branches entfernen, nur Ollama-Logik behalten
3. `core/ollama_manager.py`: `api_type`-Parameter aus `release_model` entfernen
4. `core/app_logic.py`: Dritten Parameter im `release_model`-Aufruf entfernen
5. `core/agent_manager.py`: `step_prompt` auf Original zurücksetzen
6. `agents/custom_agent_roles.json`: Neue Rollen entfernen wenn nötig
