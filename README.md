# SensePlay (DekhoSuno)

An adaptive mobile application for children with sensory impairments, designed to assist with visual and auditory challenges through AI-powered features.

## Features

### Dekho Mode (Visual Assistance)
- **Object Detection**: Identifies objects in real-time using ML Kit.
- **Text Recognition**: Reads text from the environment.
- **Scene Analysis**: Describes surroundings using Google Gemini AI.
- **Smart Camera**: AI-guided photography.

### Suno Mode (Audio Assistance)
- **Voice Commands**: Control the app hands-free.
- **Wake Word Detection**: Activates on "Hey Assistant" (using Porcupine).
- **Text-to-Speech**: feedback for all actions.

### Safety & Utilities
- **Shake-to-SOS**: Quickly send emergency alerts.
- **Light Detection**: Auditory feedback for light levels.
- **Currency Reader**: Identifies currency notes.

## Deployment

### Prerequisites
- Flutter SDK
- Android Studio / VS Code
- OpenAI / Gemini API Keys (configured in `.env`)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/chandanpandeys/DekhoSuno.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Set up environment variables:
   Create a `.env` file in the root directory with your API keys:
   ```env
   GEMINI_API_KEY=your_key_here
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
