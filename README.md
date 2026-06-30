# FlagForge 


FlagForge acts like a **remote control** for software applications. 

Usually, when developers want to turn a new feature on/off or change a setting (like a welcome message or theme color), they have to rewrite code, build a new version of the app, and make users download an update. 

With FlagForge, developers can control and update their apps in real-time from a central control panel. Changes happen instantly without requiring app updates. 

[Watch the FlagForge Demo Video](https://www.youtube.com/watch?v=1grW-zKEudw)

---

## Key Features ⚡

1. **Instant Remote Control (Feature Flags)**: Turn features on or off in your app instantly from the dashboard. 
2. **Real-Time Settings (Remote Configs)**: Change configuration settings (such as text messages or accent colors) live in seconds. ️
3. **Smart User Targeting**: 
   - **Target Groups**: Show specific features only to selected groups (like "Beta Testers").
   - **Gradual Rollouts**: Safely launch a feature to a specific percentage of users (e.g., 25% of users) to test it before a full release.
4. **Visual Terminal Dashboard**: An easy-to-use control panel running right in the command line terminal. 🖥️
5. **Autopilot Setup**: Automatically sets up a demo environment with sample projects and features on startup so you can see it in action immediately. 🚀

---

## Project Structure 📁

```text
├── backend/
│   ├── app/
│   │   ├── main.py          # Runs the server and manages client communication
│   │   ├── database.py      # Sets up the database and default sample data
│   │   ├── targeting.py     # Rules for user targeting and percentage rollouts
│   │   └── models.py        # Data structures for projects, flags, and settings
│   ├── Dockerfile           # Blueprint to run the server in a container
│   └── requirements.txt     # List of software packages required by the server
├── dashboard/
│   ├── ui.py                # Code for the terminal dashboard screen
│   └── ui.tcss              # Stylesheet defining the dashboard's look
├── client_flutter/          # Sample mobile/desktop app to demonstrate live changes
├── flagforge.db             # Local database file holding projects and flag data
└── docker-compose.yml       # Setup file to build and launch everything together
```

---

## Setup & Running Instructions 🛠️

### 1. Start the Backend API (via Docker Compose) 🐳
The easiest way to run the API with zero setup is using Docker Compose:

```bash
# Build and start the FastAPI server
docker compose up --build -d
```
* The API will start and listen on port **`8000`** (e.g., test the health check: `curl http://localhost:8000/health`).
* Interactive Swagger API documentation will be available at `http://localhost:8000/docs`.

### 2. Launch the TUI Dashboard 📟
The dashboard runs locally on the host machine to monitor and manage flags:

```bash
# 1. Create a Python virtual environment
python3 -m venv .venv
source .venv/bin/activate

# 2. Install requirements (FastAPI/TUI dependencies)
pip install -r backend/requirements.txt textual httpx websockets

# 3. Start the dashboard
python dashboard/ui.py
```
* **Controls**:
  - `Tab` / `Shift+Tab`: Navigate between panels (**Projects**, **Feature Flags**, **Remote Configs**).
  - `Spacebar`: Toggle the highlighted Feature Flag state.
  - `Enter`: Edit the highlighted Remote Config value or edit a Feature Flag's targeting rule (Choose Everyone, Beta Group, or Rollout %).
  - `r`: Refresh local states from the API.
  - `q`: Quit.

### 3. Run the Demonstration Client (Flutter App) 📱
If you do not have Flutter installed, you can set it up by following the [Official Flutter Installation Guide](https://docs.flutter.dev/get-started/install) .

Once Flutter is ready, run:
```bash
cd client_flutter
flutter pub get
flutter run
```
* The app automatically connects to the backend and dynamically changes its colors, theme, and banners in real-time based on your dashboard actions.

---

### Database Persistence 💾
* The database file is located at the root of the project: `flagforge.db`.
* Since it is committed directly to the Git repository, you will receive the exact same database.
* When you run `docker compose up`, this file is automatically mounted into the backend container, allowing you to see all current projects, feature flags, and custom settings immediately.

---

## Testing the Features & Live Sync 🧪

To see the "remote control" in action, open the **TUI Dashboard** (in your terminal) and the **Flutter App** (or the web interface at `http://localhost:8000/docs`) side-by-side:

1. **Instant Updates**: 
   - Highlight the `banner_message` setting in the TUI Dashboard and press `Enter` to change the text.
   - You will see the welcome message in the Flutter app update instantly without reloading!
2. **Gradual Releases (Rollout %)**:
   - Highlight the `premium_theme` flag in the TUI Dashboard and press `Enter`.
   - Choose **Custom Rollout %** and set it to `50%`.
   - Now, exactly 50% of your users (based on their User ID) will receive the premium theme, while the other half will not. You can test this by changing the User ID in the client to see the theme change dynamically.

