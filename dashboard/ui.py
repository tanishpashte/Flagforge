#!/usr/bin/env python3
"""
FlagForge TUI Dashboard
A btop-inspired terminal user interface for managing projects, feature flags, and remote configurations.
"""

from datetime import datetime
from typing import Any

import httpx
from textual import events
from textual.app import App, ComposeResult
from textual.containers import Grid, Horizontal, Vertical
from textual.screen import ModalScreen
from textual.widgets import Button, Footer, Input, Label, ListItem, ListView, Static


class ClockWidget(Static):
    """A live-updating clock widget for the header."""

    def on_mount(self) -> None:
        self.set_interval(1.0, self.update_time)

    def update_time(self) -> None:
        self.update(datetime.now().strftime("📅 %Y-%m-%d  🕒 %H:%M:%S"))


class CustomHeader(Static):
    """A custom application header with branding, status, and system clock."""

    def compose(self) -> ComposeResult:
        with Horizontal(id="header-container"):
            yield Static(" 󰰚  [bold #89b4fa]FLAGFORGE[/] [dim #7f849c]TUI Shell[/]", id="header-title")
            yield Static("[#a6e3a1]●[/#a6e3a1] DB: [bold #cdd6f4]Connected[/] | [#89b4fa]●[/#89b4fa] Version: [bold #cdd6f4]0.1.0[/]", id="header-status")
            yield ClockWidget()


class ProjectItem(ListItem):
    """ListItem representing a project."""

    def __init__(self, name: str, key: str, active: bool = True):
        super().__init__()
        self.project_name = name
        self.project_key = key
        self.active = active

    def compose(self) -> ComposeResult:
        icon = "󱃚"
        color = "#a6e3a1" if self.active else "#f38ba8"
        yield Label(f"[{color}]{icon}[/]  [bold #cdd6f4]{self.project_name}[/] [dim #7f849c]({self.project_key})[/]")


class FeatureFlagItem(ListItem):
    """ListItem representing a feature flag."""

    def __init__(self, flag_id: int, name: str, enabled: bool, description: str = ""):
        super().__init__()
        self.flag_id = flag_id
        self.flag_name = name
        self.enabled = enabled
        self.flag_description = description or ""

    def compose(self) -> ComposeResult:
        icon = "" if self.enabled else ""
        status_text = "ON" if self.enabled else "OFF"
        status_color = "#a6e3a1" if self.enabled else "#f38ba8"
        yield Label(
            f"[{status_color}]{icon}[/]  [bold #cdd6f4]{self.flag_name}[/] [dim #7f849c]is[/] [{status_color}]{status_text}[/]",
            id="flag-label"
        )

    def update_state(self, enabled: bool) -> None:
        self.enabled = enabled
        icon = "" if self.enabled else ""
        status_text = "ON" if self.enabled else "OFF"
        status_color = "#a6e3a1" if self.enabled else "#f38ba8"
        label = self.query_one("#flag-label", Label)
        label.update(f"[{status_color}]{icon}[/]  [bold #cdd6f4]{self.flag_name}[/] [dim #7f849c]is[/] [{status_color}]{status_text}[/]")


class RemoteConfigItem(ListItem):
    """ListItem representing a remote configuration."""

    def __init__(self, key: str, value: Any, description: str = ""):
        super().__init__()
        self.config_key = key
        self.config_value = value
        self.config_description = description or ""

    def compose(self) -> ComposeResult:
        icon = "⚙"
        val_str = str(self.config_value)
        if isinstance(self.config_value, bool):
            val_color = "#a6e3a1" if self.config_value else "#f38ba8"
        elif isinstance(self.config_value, int):
            val_color = "#f9e2af"
        else:
            val_color = "#89dceb"
            val_str = f'"{val_str}"'
        
        yield Label(
            f"[#b4befe]{icon}[/]  [bold #cdd6f4]{self.config_key}[/]: [{val_color}]{val_str}[/]",
            id="config-label"
        )

    def update_state(self, new_value: Any) -> None:
        """Update the configuration item's value and refresh its label in the UI."""
        self.config_value = new_value
        icon = "⚙"
        val_str = str(self.config_value)
        if isinstance(self.config_value, bool):
            val_color = "#a6e3a1" if self.config_value else "#f38ba8"
        elif isinstance(self.config_value, int):
            val_color = "#f9e2af"
        else:
            val_color = "#89dceb"
            val_str = f'"{val_str}"'
        
        label = self.query_one("#config-label", Label)
        label.update(f"[#b4befe]{icon}[/]  [bold #cdd6f4]{self.config_key}[/]: [{val_color}]{val_str}[/]")


class ProjectsList(ListView):
    """ListView containing project items."""

    def __init__(self) -> None:
        super().__init__(id="projects-list")
        self.border_title = "󱃚 PROJECTS"
        self.border_subtitle = "0 items"


class FeatureFlagsList(ListView):
    """ListView containing feature flag items."""

    def __init__(self) -> None:
        super().__init__(id="feature-flags-list")
        self.border_title = " FEATURE FLAGS"
        self.border_subtitle = "0 items"


class RemoteConfigsList(ListView):
    """ListView containing remote configuration items."""

    def __init__(self) -> None:
        super().__init__(id="remote-configs-list")
        self.border_title = "⚙ REMOTE CONFIGS"
        self.border_subtitle = "0 items"


class ConfigEditModal(ModalScreen):
    """A modal dialog to edit a remote configuration value."""

    BINDINGS = [
        ("escape", "cancel", "Cancel"),
    ]

    def __init__(self, key: str, value: Any) -> None:
        super().__init__()
        self.config_key = key
        self.config_value = str(value)

    def compose(self) -> ComposeResult:
        with Vertical(id="modal-dialog"):
            yield Label(f"Editing: [bold #89b4fa]{self.config_key}[/]", id="modal-label")
            yield Input(value=self.config_value, id="modal-input")
            with Horizontal(id="modal-buttons"):
                yield Button("Save", variant="success", id="modal-save")
                yield Button("Cancel", variant="error", id="modal-cancel")

    def on_mount(self) -> None:
        self.query_one("#modal-input", Input).focus()

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "modal-save":
            self.save_config()
        elif event.button.id == "modal-cancel":
            self.dismiss(None)

    def on_input_submitted(self, event: Input.Submitted) -> None:
        if event.input.id == "modal-input":
            self.save_config()

    def save_config(self) -> None:
        new_value = self.query_one("#modal-input", Input).value
        self.dismiss(new_value)

    def action_cancel(self) -> None:
        self.dismiss(None)


class FlagForgeApp(App):
    """The main TUI Application class for FlagForge."""

    CSS_PATH = "ui.tcss"
    TITLE = "FlagForge TUI Dashboard"

    BINDINGS = [
        ("q", "quit", "Quit"),
        ("tab", "focus_next", "Next Panel"),
        ("shift+tab", "focus_previous", "Prev Panel"),
        ("r", "refresh_data", "Refresh"),
    ]

    def compose(self) -> ComposeResult:
        """Compose the layout and child widgets."""
        yield CustomHeader()
        yield Input(placeholder="🔍 Search flags or configs by name...", id="search-bar")
        with Grid(id="dashboard-grid"):
            yield ProjectsList()
            with Vertical(id="right-column"):
                yield FeatureFlagsList()
                yield RemoteConfigsList()
        yield Footer()

    def on_mount(self) -> None:
        """Load backend data on startup."""
        self.run_worker(self.load_data())

    async def load_data(self) -> None:
        """Fetch real-world data from the running FastAPI HTTP backend endpoints."""
        self.notify("Fetching data from FlagForge backend...", title="Loading", severity="information")
        try:
            async with httpx.AsyncClient(base_url="http://localhost:8000") as client:
                # 1. Fetch projects
                projects_response = await client.get("/api/projects/")
                if projects_response.status_code == 200:
                    projects = projects_response.json()
                else:
                    projects = []

                # 2. Fetch flags
                flags_response = await client.get("/api/flags/")
                if flags_response.status_code == 200:
                    flags = flags_response.json()
                else:
                    flags = []

                # 3. Fetch configs for all projects
                configs = []
                for p in projects:
                    p_id = p.get("id")
                    if p_id is not None:
                        configs_response = await client.get(f"/api/configs/?project_id={p_id}")
                        if configs_response.status_code == 200:
                            configs.extend(configs_response.json())

                # Populate UI lists
                self.update_lists(projects, flags, configs)
                self.notify("Successfully loaded data from backend.", title="Sync Complete", severity="information")
        except Exception as e:
            self.notify(f"Could not connect to backend: {e}", title="Offline Mode", severity="warning")

    def update_lists(self, projects: list, flags: list, configs: list) -> None:
        """Clear and repopulate ListView widgets with fetched data."""
        # Update Projects
        proj_list = self.query_one("#projects-list", ProjectsList)
        proj_list.clear()
        for p in projects:
            proj_list.append(ProjectItem(p["name"], p.get("description") or "Active", True))
        proj_list.border_subtitle = f"{len(projects)} items"

        # Update Flags
        flags_list = self.query_one("#feature-flags-list", FeatureFlagsList)
        flags_list.clear()
        for f in flags:
            flags_list.append(FeatureFlagItem(f["id"], f["key"], f["is_enabled"], f.get("description") or ""))
        flags_list.border_subtitle = f"{len(flags)} items"

        # Update Configs
        configs_list = self.query_one("#remote-configs-list", RemoteConfigsList)
        configs_list.clear()
        for c in configs:
            configs_list.append(RemoteConfigItem(c["key"], c["value"], c.get("description") or ""))
        configs_list.border_subtitle = f"{len(configs)} items"

        # Re-apply active search filter
        search_bar = self.query_one("#search-bar", Input)
        search_query = search_bar.value.strip().lower()
        self.filter_lists(search_query)

    def on_input_changed(self, event: Input.Changed) -> None:
        """Handle live search filtering as the user types in the search bar."""
        if event.input.id == "search-bar":
            search_query = event.value.strip().lower()
            self.filter_lists(search_query)

    def on_list_view_selected(self, event: ListView.Selected) -> None:
        """Handle item selection in list views."""
        item = event.item
        if isinstance(item, RemoteConfigItem):
            self.edit_remote_config(item)

    def edit_remote_config(self, item: RemoteConfigItem) -> None:
        """Open the configuration edit modal for the selected item."""
        def handle_edit_result(new_value: str | None) -> None:
            if new_value is not None and new_value != str(item.config_value):
                self.run_worker(self.update_remote_config_value(item, new_value))

        self.push_screen(ConfigEditModal(item.config_key, item.config_value), handle_edit_result)

    async def update_remote_config_value(self, item: RemoteConfigItem, new_value: str) -> None:
        """Send asynchronous HTTP PUT request to backend to update the config value."""
        try:
            async with httpx.AsyncClient(base_url="http://localhost:8000") as client:
                response = await client.put(
                    f"/api/configs/{item.config_key}",
                    json={"value": new_value}
                )
                if response.status_code == 200:
                    data = response.json()
                    item.update_state(data["value"])
                    self.notify(
                        f"Config '{item.config_key}' updated to '{data['value']}'",
                        title="Mutation Successful",
                        severity="information"
                    )
                else:
                    self.notify(
                        f"Failed to update config: {response.status_code}",
                        title="Mutation Failed",
                        severity="error"
                    )
        except Exception as e:
            self.notify(f"Connection error: {e}", title="Network Error", severity="error")

    def filter_lists(self, query: str) -> None:
        """Filter feature flags and configs based on search query."""
        # Filter feature flags
        ff_list = self.query_one("#feature-flags-list", FeatureFlagsList)
        visible_flags = 0
        total_flags = 0
        for item in ff_list.query(FeatureFlagItem):
            total_flags += 1
            match = (
                not query or 
                query in item.flag_name.lower() or 
                query in item.flag_description.lower()
            )
            item.display = match
            if match:
                visible_flags += 1
        
        if query:
            ff_list.border_subtitle = f"Filtered: {visible_flags}/{total_flags}"
        else:
            ff_list.border_subtitle = f"{total_flags} items"

        # Filter configs
        cfg_list = self.query_one("#remote-configs-list", RemoteConfigsList)
        visible_configs = 0
        total_configs = 0
        for item in cfg_list.query(RemoteConfigItem):
            total_configs += 1
            match = (
                not query or 
                query in item.config_key.lower() or 
                query in item.config_description.lower()
            )
            item.display = match
            if match:
                visible_configs += 1
        
        if query:
            cfg_list.border_subtitle = f"Filtered: {visible_configs}/{total_configs}"
        else:
            cfg_list.border_subtitle = f"{total_configs} items"

    def on_key(self, event: events.Key) -> None:
        """Handle keyboard interactions globally."""
        if event.key == "space":
            # Avoid triggering toggling if typing in search bar
            if self.focused and self.focused.id == "search-bar":
                return
            
            focused_widget = self.focused
            if isinstance(focused_widget, FeatureFlagsList):
                highlighted = focused_widget.highlighted_child
                if isinstance(highlighted, FeatureFlagItem):
                    self.run_worker(self.toggle_feature_flag(highlighted))
                    event.prevent_default()
                    event.stop()

    async def toggle_feature_flag(self, item: FeatureFlagItem) -> None:
        """Send asynchronous HTTP PATCH request to backend to toggle the flag."""
        try:
            async with httpx.AsyncClient(base_url="http://localhost:8000") as client:
                response = await client.patch(f"/api/flags/{item.flag_id}/toggle")
                if response.status_code == 200:
                    data = response.json()
                    new_enabled = data["is_enabled"]
                    item.update_state(new_enabled)
                    self.notify(
                        f"Flag '{item.flag_name}' turned {'ON' if new_enabled else 'OFF'}",
                        title="Mutation Successful",
                        severity="information"
                    )
                else:
                    self.notify(
                        f"Failed to toggle flag: {response.status_code}",
                        title="Mutation Failed",
                        severity="error"
                    )
        except Exception as e:
            self.notify(f"Connection error: {e}", title="Network Error", severity="error")

    def action_refresh_data(self) -> None:
        """Fetch fresh data from the backend."""
        self.run_worker(self.load_data())


if __name__ == "__main__":
    app = FlagForgeApp()
    app.run()
