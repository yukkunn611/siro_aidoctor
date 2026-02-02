# siro_aidoctor

# NPC Doctor Script for QBCore

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
3. Configure settings inside the config file as needed

---

## 🎮 How It Works

1. A player becomes downed  
2. If no EMS are on duty, the player can call the NPC doctor  
3. An ambulance arrives with siren  
4. The NPC performs the revival  
5. After a successful revival, the player is billed  

---

## 🌐 Localization

All text can be edited or expanded inside the **locale files**.

You can:
- Modify existing Japanese/English translations  
- Add new languages  

---

## ⚠️ Notes

- The NPC may require enough space to reach the player  
- Make sure hospital areas are not blocked by map objects or MLO conflicts  
- Billing only occurs on successful revival by design  

---

## 🙏 Credits

Inspired by **hh_aidoc**  
Rebuilt and improved for better reliability and player experience.



