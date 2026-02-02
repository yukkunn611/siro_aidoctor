# siro_aidoctor

## 📌 Framework
**QBCore**

---

## 📝 Description

This script allows players to call an **NPC doctor** for revival when no EMS players are on duty.

It was inspired by **hh_aidoc**, but rebuilt from scratch to improve reliability.  
In the original system, there were frequent cases where the doctor arrived but did not properly revive the player. This script was created to solve that issue and provide a more consistent experience.

---

## ✨ Features

- 🚑 **NPC Revival System**  
  Players can call an NPC doctor and get revived even when no EMS are online.

- 🌍 **Multi-language Support**  
  Supports:
  - Japanese  
  - English  
  Additional languages can be added via locale files.

- 🔊 **Ambulance Siren**  
  The arriving ambulance uses a siren for a more immersive experience.

- 💰 **Post-Revival Billing**  
  Players are charged **only after revival is successfully completed**.  
  This prevents unfair charges in case the NPC fails to revive.

---

## ⚙️ Requirements

- QBCore Framework  
- A compatible hospital/respawn or death handling system

---

## 📂 Installation

1. Place this resource in your server's `resources` folder  
2. Add the following to your `server.cfg`:

