# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0-rc.4] - 2024-12-19

### 🚀 Major Features Added

#### 🔄 Continuous STT with Auto-Restart Pattern
- **Problem Solved**: Native iOS/Android STT engines have hardcoded 2-5 second silence timeouts that cannot be overridden
- **Solution**: Implemented auto-restart pattern that automatically restarts STT sessions when they end
- **Result**: True continuous speech recognition until user explicitly stops

#### 🎯 New STT Methods
- `startContinuousSTT()` - Auto-restart STT for uninterrupted recognition
- `startRecordingWithSTT()` with `continuousMode` parameter
- Smart error handling and automatic recovery mechanisms

#### 🎨 Enhanced UI Components
- "연속 STT" button for standalone continuous recognition
- "녹음+연속STT" button for recording with live transcription
- Real-time status indicators and progress feedback
- Accumulated final results display

### 📚 Documentation Overhaul

#### 📖 Complete README Rewrite
- **English README.md**: Comprehensive documentation with usage examples
- **Korean README_KR.md**: Complete Korean translation
- **Problem/Solution oriented**: Clear explanation of why this package is needed
- **Real-world use cases**: Voice note taking, interview recording, voice commands
- **Performance tips**: Best practices for optimal usage

#### 🔧 API Documentation
- Detailed `AudioSTTManager` API reference
- Method descriptions with return types
- Property explanations and status indicators
- Advanced configuration examples

### 🛠️ Technical Improvements

#### 🎤 Enhanced STT Service
- Auto-restart scheduling with 500ms delay
- Error recovery and retry mechanisms
- State management for continuous operations
- Optimized session parameters (2-minute sessions, 3-second pause detection)

#### 🔄 Smart Session Management
- `_shouldKeepListening` flag for continuous mode control
- Automatic restart on `finalResult`, `done` status, and errors
- Proper cleanup and resource management
- Callback persistence for seamless restarts

### 🎮 Example Application Updates
- New UI showcasing continuous STT features
- Real-time text accumulation display
- Status indicators for recording and STT states
- User-friendly control buttons with clear labeling

### 📱 Cross-Platform Compatibility
- iOS and Android support maintained
- Consistent behavior across platforms
- Platform-specific optimizations preserved

---

## [0.1.0-rc.3] - Previous Release
- STTService improvements and real voice recognition implementation
- Permission handling enhancements
- Example app additions

## [0.1.0-rc.2] - Previous Release  
- Fixed STTService localeId typo

## [0.1.0-rc.1] - Previous Release
- Initial release preparation

## [0.1.0] - Initial Release
- Basic audio recording functionality
- Basic speech-to-text conversion
- Cross-platform support

## [0.0.1] - 2024-12-03

### Added
- Initial project setup
- Basic package structure
