---
layout: project
title: WIZARD
date: 2026-07-27
tag: WIZARD
category: "Embodied AI · Manipulation"
excerpt: "Industrial robots need re-teaching for every new task. WIZARD uses one-shot imitation learning, developed with UC Berkeley, to adapt from a single demonstration with zero retraining."
description: "A research note on one-shot imitation learning: how a manipulation policy can be taught from a single human demonstration and still generalise to tasks it has never seen, with no retraining step."
video: "https://fascetta.github.io/WIZARD/static/videos/Real_World/Cup.mp4"
video_zoom: 1.35 # Cup.mp4 has pillarboxing baked into the source frame; scale past it so object-fit:cover shows only the footage.
has_writeup: true
stats:
  - value: "~14×"
    label: "success rate over the one-shot imitation baseline on our unseen-task evaluation set. Benchmark and protocol are in the paper."
  - value: "1"
    label: "video demonstration, then autonomy — no per-task teaching pass."
stage: "Active research project, not yet in production. Validated on real hardware in the lab."
strip:
  - label: "Collaboration"
    text: "Developed in active collaboration with UC Berkeley. Co-authored, with a public project page."
  - label: "Stage"
    text: "Active research project, not yet in production. Validated on real hardware in the lab."
  - label: "Why it matters"
    text: "Teaching cost, not peak capability, is what keeps robots out of variable environments."
in_action:
  - video: "https://fascetta.github.io/WIZARD/static/videos/LIBERO_Goal/task3_put_the_wine_bottle_on_top_of_the_cabinet.mp4"
    caption: "Wine bottle → cabinet"
  - video: "https://fascetta.github.io/WIZARD/static/videos/Real_World/Cup.mp4"
    caption: "Cup pickup · real world"
    zoom: 1.35
external_url: "https://fascetta.github.io/WIZARD/"
external_cta_label: "PROJECT PAGE"
cta_label: "READ THE PROJECT NOTE"
---
WIZARD watches a single human demonstration and extracts the underlying task structure — the sub-goals, contacts, and motions that make a task succeed — rather than memorising a trajectory. That representation is what lets it adapt instantly to new objects, positions, and environments.

Because the policy reasons about intent instead of replaying motion, it recovers from disturbances and generalises to tasks it has never explicitly been trained on — the behaviour behind the reported improvement on unseen tasks. What the figure does not yet cover is sustained operation in an industrial setting — that is the next stage of the work.
