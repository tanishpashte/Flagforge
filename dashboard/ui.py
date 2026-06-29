#!/usr/bin/env python3
"""
FlagForge TUI Dashboard
A btop-inspired terminal user interface for managing projects, feature flags, and remote configurations.
"""

import asyncio
from datetime import datetime
import json
from typing import Any

import httpx
import websockets
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

    def __init__(self, project_id: int, name: str, key: str, active: bool = True):
        super().__init__()
        self.project_id = project_id
        self.project_name = name
        self.project_key = key
        self.active = active

    def compose(self) -> ComposeResult:
        icon = "󱃚"
        color = "#a6e3a1" if self.active else "#f38ba8"
        yield Label(f"[{color}]{icon}[/]  [bold #cdd6f4]{self.project_name}[/] [dim #7f849c]({self.project_key})[/]")


def format_rule(rule: Any) -> str:
    if not rule:
        return ""
    if isinstance(rule, str):
        try:
            rule = json.loads(rule)
        except Exception:
            return ""
    if not isinstance(rule, dict):
        return ""
        
    rule_type = rule.get("type", "everyone")
    parameter = rule.get("parameter")
    
    if rule_type == "everyone":
        return ""
    elif rule_type == "group":
        if parameter == "beta":
            return " (Beta Users Only)"
        return f" (Group: {parameter})"
    elif rule_type == "rollout":
        return f" (Rollout: {parameter}%)"
    return ""


class FeatureFlagItem(ListItem):
    """ListItem representing a feature flag."""

    def __init__(self, flag_id: int, name: str, enabled: bool, description: str = "", targeting_rule: Any = None):
        super().__init__()
        self.flag_id = flag_id
        self.flag_name = name
        self.enabled = enabled
        self.flag_description = description or ""
        self.targeting_rule = targeting_rule or {"type": "everyone"}

    def compose(self) -> ComposeResult:
        icon = "" if self.enabled else ""
        status_text = "ON" if self.enabled else "OFF"
        status_color = "#a6e3a1" if self.enabled else "#f38ba8"
        rule_text = format_rule(self.targeting_rule)
        yield Label(
            f"[{status_color}]{icon}[/]  [bold #cdd6f4]{self.flag_name}[/] [dim #7f849c]is[/] [{status_color}]{status_text}[/]{rule_text}",
            id="flag-label"
        )

    def update_state(self, enabled: bool, targeting_rule: Any = None) -> None:
        self.enabled = enabled
        if targeting_rule is not None:
            self.targeting_rule = targeting_rule
        icon = "" if self.enabled else ""
        status_text = "ON" if self.enabled else "OFF"
        status_color = "#a6e3a1" if self.enabled else "#f38ba8"
        rule_text = format_rule(self.targeting_rule)
        label = self.query_one("#flag-label", Label)
        label.update(f"[{status_color}]{icon}[/]  [bold #cdd6f4]{self.flag_name}[/] [dim #7f849c]is[/] [{status_color}]{status_text}[/]{rule_text}")


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


class FlagRuleModal(ModalScreen):
    """A modal dialog to edit a feature flag's targeting rule."""

    BINDINGS = [
        ("escape", "cancel", "Cancel"),
    ]

    def __init__(self, flag_key: str, current_rule: dict) -> None:
        super().__init__()
        self.flag_key = flag_key
        self.current_rule = current_rule or {"type": "everyone"}

    def compose(self) -> ComposeResult:
        with Vertical(id="rule-modal-dialog"):
            yield Label(f"Targeting Rule: [bold #89b4fa]{self.flag_key}[/]", id="rule-modal-label")
            with ListView(id="rule-type-list"):
                yield ListItem(Label("Everyone"), id="rule-everyone")
                yield ListItem(Label("Beta Users Only"), id="rule-beta")
                yield ListItem(Label("Custom Rollout %"), id="rule-rollout")
            with Vertical(id="rollout-input-container"):
                yield Label("Specify Rollout Percentage (0-100):")
                initial_pct = ""
                if self.current_rule.get("type") == "rollout":
                    initial_pct = str(self.current_rule.get("parameter") or "")
                yield Input(value=initial_pct, placeholder="e.g. 25", id="rollout-input")
            with Horizontal(id="rule-modal-buttons"):
                yield Button("Save", variant="success", id="rule-modal-save")
                yield Button("Cancel", variant="error", id="rule-modal-cancel")

    def on_mount(self) -> None:
        list_view = self.query_one("#rule-type-list", ListView)
        container = self.query_one("#rollout-input-container")
        
        rule_type = self.current_rule.get("type", "everyone")
        parameter = self.current_rule.get("parameter")
        
        if rule_type == "everyone":
            list_view.index = 0
            container.display = False
        elif rule_type == "group" and parameter == "beta":
            list_view.index = 1
            container.display = False
        elif rule_type == "rollout":
            list_view.index = 2
            container.display = True
        else:
            list_view.index = 0
            container.display = False
            
        list_view.focus()

    def on_list_view_highlighted(self, event: ListView.Highlighted) -> None:
        item = event.item
        container = self.query_one("#rollout-input-container")
        if item is not None:
            if item.id == "rule-rollout":
                container.display = True
            else:
                container.display = False

    def on_list_view_selected(self, event: ListView.Selected) -> None:
        item = event.item
        if item is not None:
            if item.id == "rule-rollout":
                container = self.query_one("#rollout-input-container")
                container.display = True
                self.query_one("#rollout-input", Input).focus()
            else:
                self.save_rule()

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "rule-modal-save":
            self.save_rule()
        elif event.button.id == "rule-modal-cancel":
            self.dismiss(None)

    def on_input_submitted(self, event: Input.Submitted) -> None:
        if event.input.id == "rollout-input":
            self.save_rule()

    def save_rule(self) -> None:
        list_view = self.query_one("#rule-type-list", ListView)
        index = list_view.index
        
        if index == 0:
            new_rule = {"type": "everyone", "parameter": None}
        elif index == 1:
            new_rule = {"type": "group", "parameter": "beta"}
        elif index == 2:
            pct_val = self.query_one("#rollout-input", Input).value.strip()
            if not pct_val:
                pct_val = "0"
            new_rule = {"type": "rollout", "parameter": pct_val}
        else:
            new_rule = {"type": "everyone", "parameter": None}
            
        self.dismiss(new_rule)

    def action_cancel(self) -> None:
        self.dismiss(None)


class FlagForgeApp(App):
    """The main TUI Application class for FlagForge."""

    CSS_PATH = "ui.tcss"
    TITLE = "FlagForge TUI Dashboard"

    def __init__(self, **kwargs) -> None:
        super().__init__(**kwargs)
        self.active_ws_projects = set()

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

                # Find the default active project (first project)
                default_project_id = None
                if projects:
                    default_project_id = projects[0].get("id")

                # 2. Fetch flags for default project
                flags = []
                if default_project_id is not None:
                    flags_response = await client.get(f"/api/flags/?project_id={default_project_id}")
                    if flags_response.status_code == 200:
                        flags = flags_response.json()

                # 3. Fetch configs for default project
                configs = []
                if default_project_id is not None:
                    configs_response = await client.get(f"/api/configs/?project_id={default_project_id}")
                    if configs_response.status_code == 200:
                        configs = configs_response.json()

                # Populate UI lists
                self.update_lists(projects, flags, configs)
                self.notify("Successfully loaded data from backend.", title="Sync Complete", severity="information")

                # Start WebSocket listeners for projects
                for p in projects:
                    p_id = p.get("id")
                    if p_id is not None and p_id not in self.active_ws_projects:
                        self.active_ws_projects.add(p_id)
                        self.run_worker(self.listen_websocket(p_id))
        except Exception as e:
            self.notify(f"Could not connect to backend: {e}", title="Offline Mode", severity="warning")

    def update_lists(self, projects: list, flags: list, configs: list) -> None:
        """Clear and repopulate ListView widgets with fetched data."""
        # Update Projects
        proj_list = self.query_one("#projects-list", ProjectsList)
        proj_list.clear()
        for p in projects:
            proj_list.append(ProjectItem(p["id"], p["name"], p.get("description") or "Active", True))
        proj_list.border_subtitle = f"{len(projects)} items"

        # Update Flags
        flags_list = self.query_one("#feature-flags-list", FeatureFlagsList)
        flags_list.clear()
        for f in flags:
            flags_list.append(FeatureFlagItem(f["id"], f["key"], f["is_enabled"], f.get("description") or "", f.get("targeting_rule")))
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
        elif isinstance(item, FeatureFlagItem):
            self.edit_feature_flag_rule(item)
        elif isinstance(item, ProjectItem):
            self.run_worker(self.fetch_project_data(item.project_id))

    def on_list_view_highlighted(self, event: ListView.Highlighted) -> None:
        """Handle highlight changes in list views."""
        if event.list_view.id == "projects-list":
            item = event.item
            if isinstance(item, ProjectItem):
                self.run_worker(self.fetch_project_data(item.project_id))

    async def fetch_project_data(self, project_id: int) -> None:
        """Fetch flags and configs for a specific project asynchronously."""
        try:
            async with httpx.AsyncClient(base_url="http://localhost:8000") as client:
                # 1. Fetch flags for project_id
                flags_response = await client.get(f"/api/flags/?project_id={project_id}")
                flags = flags_response.json() if flags_response.status_code == 200 else []

                # 2. Fetch configs for project_id
                configs_response = await client.get(f"/api/configs/?project_id={project_id}")
                configs = configs_response.json() if configs_response.status_code == 200 else []

                # Repopulate UI
                self.repopulate_flags_and_configs(flags, configs)
        except Exception:
            # Silence background network errors if backend offline
            pass

    def repopulate_flags_and_configs(self, flags: list, configs: list) -> None:
        """Clear and repopulate the feature flags and configs ListViews."""
        # Update Flags
        flags_list = self.query_one("#feature-flags-list", FeatureFlagsList)
        flags_list.clear()
        for f in flags:
            flags_list.append(FeatureFlagItem(f["id"], f["key"], f["is_enabled"], f.get("description") or "", f.get("targeting_rule")))
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

    def edit_remote_config(self, item: RemoteConfigItem) -> None:
        """Open the configuration edit modal for the selected item."""
        def handle_edit_result(new_value: str | None) -> None:
            if new_value is not None and new_value != str(item.config_value):
                self.run_worker(self.update_remote_config_value(item, new_value))

        self.push_screen(ConfigEditModal(item.config_key, item.config_value), handle_edit_result)

    async def update_remote_config_value(self, item: RemoteConfigItem, new_value: str) -> None:
        """Send asynchronous HTTP PUT request to backend to update the config value."""
        try:
            async with httpx.AsyncClient(base_url="http://127.0.0.1:8000") as client:
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

    async def listen_websocket(self, project_id: int) -> None:
        """Listen to real-time events from the backend WebSocket stream for a project."""
        uri = f"ws://127.0.0.1:8000/api/stream/{project_id}"
        while True:
            try:
                async with websockets.connect(uri) as websocket:
                    while True:
                        try:
                            message_str = await websocket.recv()
                            message = json.loads(message_str)
                            self.handle_ws_message(message)
                        except websockets.ConnectionClosed:
                            break
                        except Exception:
                            pass
            except Exception:
                # Connection failed, retry after a delay
                await asyncio.sleep(5)

    def handle_ws_message(self, message: dict) -> None:
        """Process incoming WebSocket broadcast message to update the TUI state cleanly without duplicating items."""
        msg_type = message.get("type")
        action = message.get("action")
        key = message.get("key")

        if msg_type == "config":
            value = message.get("value")
            configs_list = self.query_one("#remote-configs-list", RemoteConfigsList)
            
            # Find existing item to update in-place
            found = False
            for item in configs_list.query(RemoteConfigItem):
                if item.config_key == key:
                    if action == "delete":
                        configs_list.remove(item)
                    else:
                        item.update_state(value)
                    found = True
                    break
            
            # If not found and not a deletion, append new item
            if not found and action != "delete":
                configs_list.append(RemoteConfigItem(key, value, ""))
                
            # Update subtitle count
            total_items = len(configs_list.query(RemoteConfigItem))
            configs_list.border_subtitle = f"{total_items} items"
            
        elif msg_type == "flag":
            is_enabled = message.get("is_enabled")
            targeting_rule = message.get("targeting_rule")
            flags_list = self.query_one("#feature-flags-list", FeatureFlagsList)
            
            # Find existing item to update in-place
            found = False
            for item in flags_list.query(FeatureFlagItem):
                if item.flag_name == key:
                    if action == "delete":
                        flags_list.remove(item)
                    else:
                        item.update_state(is_enabled, targeting_rule)
                    found = True
                    break
                    
            # If not found and not a deletion, append new item
            if not found and action != "delete":
                flags_list.append(FeatureFlagItem(0, key, is_enabled, "", targeting_rule))
                
            # Update subtitle count
            total_items = len(flags_list.query(FeatureFlagItem))
            flags_list.border_subtitle = f"{total_items} items"

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

    def edit_feature_flag_rule(self, item: FeatureFlagItem) -> None:
        """Open the targeting rule edit modal for the selected feature flag."""
        def handle_edit_result(new_rule: dict | None) -> None:
            if new_rule is not None:
                self.run_worker(self.update_feature_flag_rule(item, new_rule))

        self.push_screen(FlagRuleModal(item.flag_name, item.targeting_rule), handle_edit_result)

    async def update_feature_flag_rule(self, item: FeatureFlagItem, new_rule: dict) -> None:
        """Send asynchronous HTTP PUT request to backend to update the flag's targeting rule."""
        try:
            async with httpx.AsyncClient(base_url="http://127.0.0.1:8000") as client:
                response = await client.put(
                    f"/api/flags/{item.flag_name}/rule",
                    json=new_rule
                )
                if response.status_code == 200:
                    data = response.json()
                    item.update_state(data["is_enabled"], data.get("targeting_rule"))
                    self.notify(
                        f"Rule for '{item.flag_name}' updated successfully.",
                        title="Mutation Successful",
                        severity="information"
                    )
                else:
                    self.notify(
                        f"Failed to update rule: {response.status_code}",
                        title="Mutation Failed",
                        severity="error"
                    )
        except Exception as e:
            self.notify(f"Connection error: {e}", title="Network Error", severity="error")

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
                    item.update_state(new_enabled, data.get("targeting_rule"))
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
