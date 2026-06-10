#!/usr/bin/env python3
"""
FlagForge TUI Dashboard
A btop-inspired terminal user interface for managing projects, feature flags, and remote configurations.
"""

from datetime import datetime
from typing import Any

from textual.app import App, ComposeResult
from textual.containers import Grid, Horizontal, Vertical
from textual.widgets import Footer, Label, ListItem, ListView, Static


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

    def __init__(self, name: str, enabled: bool):
        super().__init__()
        self.flag_name = name
        self.enabled = enabled

    def compose(self) -> ComposeResult:
        icon = "" if self.enabled else ""
        status_text = "ON" if self.enabled else "OFF"
        status_color = "#a6e3a1" if self.enabled else "#f38ba8"
        yield Label(f"[{status_color}]{icon}[/]  [bold #cdd6f4]{self.flag_name}[/] [dim #7f849c]is[/] [{status_color}]{status_text}[/]")


class RemoteConfigItem(ListItem):
    """ListItem representing a remote configuration."""

    def __init__(self, key: str, value: Any):
        super().__init__()
        self.config_key = key
        self.config_value = value

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
        
        yield Label(f"[#b4befe]{icon}[/]  [bold #cdd6f4]{self.config_key}[/]: [{val_color}]{val_str}[/]")


class ProjectsList(ListView):
    """ListView containing project items."""

    def __init__(self) -> None:
        items = [
            ProjectItem("Main Backend Service", "main-backend", True),
            ProjectItem("React Frontend Admin", "react-admin", True),
            ProjectItem("Staging API Gateway", "staging-gateway", True),
            ProjectItem("Mobile Application", "ios-android-app", False),
        ]
        super().__init__(*items, id="projects-list")
        self.border_title = "󱃚 PROJECTS"
        self.border_subtitle = f"{len(items)} items"


class FeatureFlagsList(ListView):
    """ListView containing feature flag items."""

    def __init__(self) -> None:
        items = [
            FeatureFlagItem("new-billing-flow", True),
            FeatureFlagItem("beta-dashboard-v2", False),
            FeatureFlagItem("maintenance-mode", False),
            FeatureFlagItem("graphql-api-migration", True),
        ]
        super().__init__(*items, id="feature-flags-list")
        self.border_title = " FEATURE FLAGS"
        self.border_subtitle = f"{len(items)} items"


class RemoteConfigsList(ListView):
    """ListView containing remote configuration items."""

    def __init__(self) -> None:
        items = [
            RemoteConfigItem("max_retry_attempts", 5),
            RemoteConfigItem("session_timeout_seconds", 3600),
            RemoteConfigItem("api_base_url", "https://api.flagforge.dev"),
            RemoteConfigItem("allow_public_registrations", True),
        ]
        super().__init__(*items, id="remote-configs-list")
        self.border_title = "⚙ REMOTE CONFIGS"
        self.border_subtitle = f"{len(items)} items"


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
        with Grid(id="dashboard-grid"):
            yield ProjectsList()
            with Vertical(id="right-column"):
                yield FeatureFlagsList()
                yield RemoteConfigsList()
        yield Footer()

    def action_refresh_data(self) -> None:
        """Simulate refreshing dashboard data."""
        self.notify("Refreshing dashboard data from database...", title="Syncing", severity="information")


if __name__ == "__main__":
    app = FlagForgeApp()
    app.run()
