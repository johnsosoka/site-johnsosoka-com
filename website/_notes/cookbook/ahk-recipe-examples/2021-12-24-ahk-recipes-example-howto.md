---
layout: note
title: AutoHotKey Notes, Recipes & Examples
note_type: AHK Scripting
---

Test one two

```
GenerateThinkFace() {
	ThinkingFace := ":marinethonk:"
	Random, thinkRando, 0, 10
	if (thinkRando > 7)
	{
		ThinkingFace := ":thinking:"
	}
	
	return ThinkingFace
}
```