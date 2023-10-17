# AI-Horde-Client-Addon

A Godot addon for using the [AI Horde](https://aihorde.net/) from Godot. It allows games to utilize free dynamic image generations using Stable Diffusion on a crowdsourced cluster.

Adding this Plugin will provide you with a StableHordeClient Node and class. This Node provides exported variables to fill in with the kind of generation you want to achieve from Stable Diffusion

# API Key

While you can use this plugin anonymously, by using the api_key '0000000000', depending on the load on the horde, this can take a while. If you [generate a unique api_key for yourself](https://aihorde.net/register) you can use it to join the horde with your own PC and receive kudos for generating for others, which will increase your priority on the horde.

# Generating

When you call the generate function, it will use the exported variables you've provided to send the generation to the AI Horde and wait for the reply.

You can also send an ad-hoc bypass prompt or parameters to the generate function, which will override the exported variables. When the generation is complete, The StableHordeClient will convert the image data into textures and send them with its `images_generated` signal. You can afterwards also find them again in its `latest_image_textures` and `all_image_textures` arrays.

# Nodes

This addon provides the following nodes to use

* StableHordeClient: Generate an Image using Stable Diffusion on the AI Horde
* StableHordeModels: Retrieve and filter information about available model checkpoints on the AI Horde
* CivitAILoraReference: Retrieve and filter information about Loras on CivitAI
* CivitAITIReference: Retrieve and filter information about TIs on CivitAI
* StableHordeRateGeneration: Submit ratings for images

There's a few other helper nodes, but these are the primary ones you should use directly

# Demo

Run this project using the Demo scene. Press the button to keep generating new images into the grid.

You can also try out [Lucid Creations](https://github.com/db0/Lucid-Creations) which is my fully-fledged client using this addon.
