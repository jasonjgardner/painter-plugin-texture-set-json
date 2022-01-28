import QtQuick 2.7
import Painter 1.0

PainterPlugin
{
	// Disable update and server settings
	tickIntervalMS: -1 // Disabled Tick
	jsonServerPort: -1 // Disabled JSON server

	Component.onCompleted:
	{
		var toolbarBtn = alg.ui.addToolBarWidget("toolbar.qml");

		if (toolbarBtn) {
			toolbarBtn.clicked.connect(exportTextureSetJson);
		}
	}

	function exportTextureSetJson()
	{
		try {
			if (!alg.project.isOpen()) {
				return;
			}

			var doc = alg.mapexport.documentStructure();

			// Save to export directory:
			var dir = alg.mapexport.exportPath();
			
			// (or save to project directory)
			//var dir = alg.fileIO.urlToLocalFile(alg.project.url())

			dir = dir.substring(0, dir.lastIndexOf("/"));

			// Export a texture set JSON file for each material in the project
			doc.materials.forEach(function(material) {
				var textureSetData = {};
				var textureSetName = material.name;

				// Check material for which channels will be available in the texture set file.
				material.stacks.forEach(function(stack) {
					var channels = stack.channels;

					// (Color layer is required)
					if (channels.includes("basecolor")) {
						textureSetData.color = textureSetName;
					}

					// Include MER map if metallic, emissive and/or roughness channels are present
					if (channels.includes("metallic") || channels.includes("emissive") || channels.includes("roughness")) {
						textureSetData.metalness_emissive_roughness = textureSetName + "_mer";
					}

					// Prefer normal map over heightmap
					if (channels.includes("normal")) {
						textureSetData.normal = textureSetName + "_normal";
					} else if (channels.includes("height")) {
						// Heightmap and normal map properties are mutually exclusive
						textureSetData.heightmap = textureSetName + "_heightmap";
					}
				})

				// Write texture set file if the project contains the required channels
				if (textureSetData.hasOwnProperty("color")) {
					var fileName = dir + "/" + textureSetName + ".texture_set.json";
					var jsonFile = alg.fileIO.open(fileName, "r+");

					jsonFile.write(
						JSON.stringify({
							"format_version": "1.16.100",
							"minecraft:texture_set": textureSetData
						}, null, "\t")
					);
					jsonFile.close();

					alg.log.info("Texture set JSON file saved!");
            		alg.log.info(fileName);
					return;
				}
			});
		}
		catch (error) {
			alg.log.exception(error);
		}
	}
}