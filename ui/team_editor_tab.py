# ArtAgent/ui/team_editor_tab.py
import gradio as gr
from core.help_content import get_tooltip # Assuming help content is added later

def create_team_editor_tab(initial_team_names, initial_available_agent_names):
    """Creates the Gradio components for the Agent Team Editor tab."""

    with gr.Tab("Agent Team Editor"):
        gr.Markdown("## Create and Edit Agent Workflows (Teams)")
        gr.Markdown("Define sequences of agents to perform complex tasks. Saved teams appear in the Chat tab dropdown.")

        # State to hold the data for the team currently being edited
        current_team_editor_state = gr.State(value={
            "name": "", "description": "", "steps": [], "assembly_strategy": "concatenate"
        })

        with gr.Row():
            with gr.Column(scale=1):
                gr.Markdown("### Load / Manage Teams")
                team_select_dropdown = gr.Dropdown(
                    choices=initial_team_names, label="Select Team to Load/Edit"
                )
                load_team_button = gr.Button("Load Selected Team")
                delete_team_button = gr.Button("Delete Selected Team", variant="stop")
                clear_editor_button = gr.Button("Clear Editor / New Team")

            with gr.Column(scale=2):
                gr.Markdown("### Team Details")
                team_name_textbox = gr.Textbox(label="Team Name")
                team_description_textbox = gr.Textbox(label="Team Description", lines=2)
                assembly_strategy_radio = gr.Radio(
                    choices=[
                        "concatenate", 
                        "refine_last", 
                        "summarize_all", 
                        "structured_concatenate",
                        "metaphorical_synthesis",
                        "conceptual_blend",
                        "stylistic_mashup"
                    ],
                    value="concatenate",
                    label="Final Output Strategy"
                )
                # The 'info' text is now a separate Markdown component for rich formatting
                gr.Markdown(
                    """
                    - **concatenate**: Joins all step outputs directly.
                    - **refine_last**: Uses only the last agent's output.
                    - **summarize_all**: A final LLM call synthesizes all outputs into a coherent whole.
                    - **structured_concatenate**: Joins outputs with clear labels for each agent/step.
                    - **metaphorical_synthesis**: Dynamically chooses a metaphor to creatively reinterpret the combined inputs.
                    - **conceptual_blend**: Fuses the core ideas from all steps into a novel, hybrid concept.
                    - **stylistic_mashup**: Dynamically chooses a literary or textual style and rewrites the combined inputs.
                    """
                )

        gr.Markdown("---")
        gr.Markdown("### Define Workflow Steps")

        with gr.Row():
            with gr.Column(scale=2):
                steps_display_json = gr.JSON(label="Current Steps (Read-Only View)", scale=2)

            with gr.Column(scale=1):
                gr.Markdown("#### Add/Remove Steps")
                agent_to_add_dropdown = gr.Dropdown(
                    choices=initial_available_agent_names, label="Select Agent Role for New Step"
                )
                add_step_button = gr.Button("Add Selected Agent as Step", variant="secondary")
                gr.Markdown("---")
                step_index_to_remove = gr.Number(label="Step Number to Remove", minimum=1, precision=0, value=1)
                remove_step_button = gr.Button("Remove Step #", variant="secondary")

        gr.Markdown("---")
        with gr.Row():
             save_team_button = gr.Button("Save Current Team Definition", variant="primary")
             save_status_textbox = gr.Textbox(label="Status", interactive=False)

    # Return dictionary of components needed for wiring
    return {
        "team_select_dropdown": team_select_dropdown,
        "load_team_button": load_team_button,
        "delete_team_button": delete_team_button,
        "clear_editor_button": clear_editor_button,
        "team_name_textbox": team_name_textbox,
        "team_description_textbox": team_description_textbox,
        "assembly_strategy_radio": assembly_strategy_radio,
        "steps_display_json": steps_display_json,
        "agent_to_add_dropdown": agent_to_add_dropdown,
        "add_step_button": add_step_button,
        "step_index_to_remove": step_index_to_remove,
        "remove_step_button": remove_step_button,
        "save_team_button": save_team_button,
        "save_status_textbox": save_status_textbox,
        "current_team_editor_state": current_team_editor_state,
    }