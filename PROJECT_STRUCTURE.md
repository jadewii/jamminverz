# Todomai iOS Project Structure

## ✅ EXACT 1:1 Port from watchOS

### Navigation Architecture
```
ContentView (Root Navigation Controller)
├── MenuView (Main screen)
│   ├── TODAY → TodayView
│   ├── THIS WEEK → ThisWeekView → DayView
│   ├── DONE/CALENDAR → CalendarView → DayView
│   └── LATER/SOMEDAY → LaterView
└── Mode Button
    ├── Tap → GetItDoneView
    │   ├── MODES → ModesView
    │   ├── DO 1 THING/FOCUS/STUDY → PriorityView
    │   ├── ROULETTE/PLAN/REVIEW → (Mode specific)
    │   └── SETTINGS → SettingsView
    └── Long Press → Cycle modes
```

### Files to Share with watchOS
- `TodomaiApp.swift` - Task, TaskList, ViewMode models (SHARED)
- `AnimatedTaskRow.swift` - Task row component (ADAPT)
- `TaskStore.swift` - Core business logic (SHARED)

### iOS-Specific Adaptations
- Scale dimensions by 1.3x for phone (32pt → 42pt buttons)
- Keep exact color values
- Keep exact font weights and styles
- NO corner radius on menu buttons (Rectangle, not RoundedRectangle)
- Black borders everywhere (6pt width)

### Features Implemented
1. **Navigation**: String-based tab switching (not NavigationView)
2. **Modes**: Life/Work/School with different button sets
3. **Lists**: Today, This Week, Calendar/Done, Later/Someday
4. **Gestures**: Swipe right to go back
5. **Haptics**: Light tap, medium long press

### What's NOT in this app
- NO native iOS calendar
- NO system settings
- NO tab bars
- NO navigation stacks
- NO default UI components

This is YOUR custom app, ported exactly as designed.