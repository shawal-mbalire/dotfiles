.pragma library

// Builder for LaunchPort AppEntry values.
function app(name, extra) {
  const base = { id: name.toLowerCase() + ".desktop", name: name, genericName: "", comment: "", keywords: [], iconSource: "" }
  return Object.assign(base, extra || {})
}

const SAMPLE = [
  app("Firefox", { genericName: "Web Browser", keywords: ["internet", "www"] }),
  app("Files", { genericName: "File Manager" }),
  app("GNU Image Manipulation Program", { genericName: "Image Editor" }),
  app("kitty", { genericName: "Terminal Emulator" }),
  app("Visual Studio Code", { comment: "Code editing. Redefined." })
]
