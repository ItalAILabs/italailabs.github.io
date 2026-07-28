---
layout: project
title: WIZARD
date: 2026-07-27
tag: WIZARD
category: "Embodied AI · Manipulation"
excerpt: "A robot that watches once, adapts instantly, and operates in the real world. Frontier science becoming industrial reality."
description: "A robot that watches once, adapts instantly, and operates in the real world. WIZARD turns a single demonstration into robust, generalising behaviour — no retraining required."
video: "https://fascetta.github.io/WIZARD/static/videos/Real_World/Cup.mp4"
video_zoom: 1.35 # Cup.mp4 has pillarboxing baked into the source frame; scale past it so object-fit:cover shows only the footage.
stats:
  - value: "~14×"
    label: "performance on unseen tasks, zero retraining required"
  - value: "1"
    label: "video demonstration is all it takes"
in_action:
  - video: "https://fascetta.github.io/WIZARD/static/videos/LIBERO_Goal/task3_put_the_wine_bottle_on_top_of_the_cabinet.mp4"
    caption: "Wine bottle → cabinet"
  - video: "https://fascetta.github.io/WIZARD/static/videos/Real_World/Cup.mp4"
    caption: "Cup pickup · real world"
    zoom: 1.35
external_url: "https://fascetta.github.io/WIZARD/"
external_cta_label: "PROJECT PAGE"
cta_label: "VIEW PROJECT"
---
WIZARD watches a single human demonstration and extracts the underlying task structure — the sub-goals, contacts, and motions that make a task succeed — rather than memorising a trajectory. That representation is what lets it adapt instantly to new objects, positions, and environments.

Because the policy reasons about intent instead of replaying motion, it recovers from disturbances and generalises to tasks it has never explicitly been trained on — the behaviour behind the ~14× improvement on unseen tasks.
