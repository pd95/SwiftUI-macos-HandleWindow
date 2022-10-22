# macOS SwiftUI window playground

This is my personal playground where I'm learning and testing SwiftUI functionality related to multi-window support
in macOS apps.

So far, I've written a custom `WindowAccessor` implementation (inspired by the ones found on StackOverflow) which allows
me to not only access `NSWindow` instance, but also being called-back when the view is inserted into the window and 
whenever the window becomes visible/invisible. This allows configuring and positioning a view on screen without flicker!  

The project contains currently the following major components:

- `WindowAccessor` used to track the addition of a SwiftUI view to a window (in a background view).
  It uses the embedded `WindowMonitor` class as a coordinator and to notify callbacks when view has been added or removed
  from the window. The monitor automatically releases itself when `willCloseNotification` for the given window is received. 
- `WindowTracker` is a SwiftUI view modifier to embed the `WindowAccessor` and inject a `WindowState` environment variable
  which can be used by the child views to get access to the `underlyingWindow` or the `WindowMonitor` to track additional
  `NSWindow` attributes
- `ManagedWindow` and `ManagedWindowGroup` are SwiftUI scenes (replacing `WindowGroup`) which can be used to easily create
  multi-window apps (without upgrading to macOS Ventura!). `ManagedWindow` is a single-window scene. It is impossible to
  open more than one at time. `ManagedWindowGroup` is a group of similar windows.
- `WindowManager` is the manager of the new window scenes. He makes sure only one instance of a `ManagedWindow` can be 
  opened and also ensures the last window position (per kind) is persisted.
- [`HandleWindowApp.swift`](HandleWindow/HandleWindowApp.swift) is an example how to use it.

There is still a lot which can be improved...

---

The knowledge I gained so far:

- The `id` parameter of a `WindowGroup` plays a crucial role in persisting the window position, because it will be used
  to derive the underlying `NSWindow.identifier`.

  If you do not set an ID it will be automatically derived from views type! For example:

      HandleWindow.ContentView-1-AppWindow-1

  By fixing the `id` parameter to "main", the identifier for the first window becomes "main-AppWindow-1" and
  "main-AppWindow-2" for the second,  "main-AppWindow-3" for the third.

- The `NSWindow.identifier` (derived from the `WindowGroup.id`) is used to define the windows `frameAutosaveName`
  (i.e. it has by default the same value). This "frame autosave name", is used to persist the windows frame in your apps 
  standard settings (`UserDefaults.standard`). The key used is derived:

      NSWindow Frame <frame autosave name>-AppWindow-1

  I.e. in our example using "main", the window will persist the position under the key:
  
      NSWindow Frame main-AppWindow-1
      
  The value stored under this location consists of the windows frame and the screens dimension in String representation
  called `NSWindow.PersistableFrameDescriptor`. For example 

      1450 883 108 80 0 0 3008 1228 

  The first 4 values represent the origin (x, y) and the size (width, height) of the window. The next 4 values represent
  the screen frame: origin and size.

- SwiftUI does a poor job on remembering window positions!

  1. It persists the position of a single window of an entire group. Even though you can have multiple windows open.
     Only one will be reopened: the one which was frontmost when the app closed.
  2. After app launch, when moving the opened window, closing it and reopening it again (CMD + N), does not reopen it
     near the position where we closed it!

  It seems that SwiftUI treats each window as a unique entity and therefore gives it a unique identifier (with 
  increasing sequence numbers at the end). Worst of all: in the standard preferences you will always see only one 
  single entry per `WindowGroup` which corresponds to the last "topped" window.
  This is very annoying if you display the same `ContentView` in the same window (for example a Welcome screen). Closing
  and reopening it will make it jump location on the screen.
