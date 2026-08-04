# 📚 Nexus UI Library — Technical Documentation

Welcome to the complete technical documentation for **Nexus UI Library**, a sleek, high-performance dark-themed user interface framework built for Roblox script development and executor environments.

---

## 📑 Table of Contents
1. [Overview & Architecture](#-overview--architecture)
2. [Installation & Initialization](#-installation--initialization)
3. [Library API Reference](#-library-api-reference)
   - [`Library:AddWindow`](#libraryaddwindowtitletext-defaultposition-hubname-togglekey)
   - [`Library:Notify`](#librarynotifytitle-text-duration)
   - [`Library:CreateSettingsWindow`](#librarycreatesettingswindow)
4. [Window API Reference (`WindowAPI`)](#-window-api-reference-windowapi)
   - [`Window:AddButton`](#windowaddbuttontext-callback)
   - [`Window:AddToggle`](#windowaddtoggletext-default-callback)
   - [`Window:AddSlider`](#windowaddslidertext-min-max-default-callback)
   - [`Window:AddTextBox`](#windowaddtextboxtext-defaulttext-callback)
   - [`Window:AddLabel`](#windowaddlabeltext)
5. [Configuration & Persistence](#-configuration--persistence)
6. [Theme & Customization System](#-theme--customization-system)
7. [Full Implementation Example](#-full-implementation-example)
8. [Executor Compatibility & Fallbacks](#-executor-compatibility--fallbacks)

---

## 📸 Overview & Architecture

Nexus UI Library is structured using object-oriented functional principles in Luau. It abstracts UI creation into modular windows and containerized components.

* **Accent Color:** Crimson Red (`RGB 220, 35, 35`)
* **Default Toggle Keybind:** `RightShift`
* **Configuration Storage:** `NexusUI_Config.json`
* **Parenting Hierarchy:** `CoreGui` (with `syn.protect_gui` protection when available) $\rightarrow$ `PlayerGui` (fallback).

---

## ⚡ Installation & Initialization

To integrate Nexus UI into your script, load the library source via `game:HttpGet`:

```lua
local Library = loadstring(game:HttpGet("[https://raw.githubusercontent.com/minecraftpe012/Nexus-UI-Libary/refs/heads/main/src.lua](https://raw.githubusercontent.com/minecraftpe012/Nexus-UI-Libary/refs/heads/main/src.lua)"))()
