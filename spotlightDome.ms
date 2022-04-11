SLD_light_controller = bezier_float()

function F_GetColorValue dome uv_vertex =( -- finds the color of the pixel based on UV position
	texture_map = dome.material.base_color_map.bitmap
	uv_position = meshop.getMapVert dome 1 uv_vertex
	uv_position.x = mod uv_position.x 1.0
	if uv_position.x < 0 do ( uv_position.x += 1)
	uv_position.y = mod uv_position.y 1.0
	if uv_position.y < 0 do ( uv_position.y += 1)
	
	pixel_position = [(int)(texture_map.width * uv_position.x),(int)(texture_map.height * (1-uv_position.y))]
	if pixel_position.x == texture_map.width do (pixel_position.x -= 1)
	if pixel_position.y == texture_map.height do (pixel_position.y -= 1)
	spotlight_color = getPixels texture_map pixel_position 1
	return spotlight_color 
)

function F_CreateSpotlights dome =( --Create the spotlights on the dome verticies
		--create and assign layer
	dome_layer = LayerManager.getLayerFromName "_LightDome"
	if dome_layer == undefined do (
		dome_layer = LayerManager.newLayerFromName "_LightDome"
	)
	dome_layer.addnode dome
	
	-- create and place the spotlights
	target_pos = dome.pivot
	vert_list = #{1..dome.numverts}
	for i = 1 to (getNumFaces dome) do (
		mesh_face = getFace dome i
		map_face = meshop.getMapFace dome 1 i
		for j = 1 to 3 do (
			if findItem vert_list ((int)mesh_face[j]) != 0 do (
				spotlight = targetSpot pos:(getVert dome mesh_face[j]) target:(Targetobject pos:target_pos)
				spotlight_color = F_GetColorValue dome mesh_face[j]
				spotlight.rgb = spotlight_color[1]
				spotlight.wirecolor = spotlight_color[1]
				spotlight.multiplier.controller = SLD_light_controller
				dome_layer.addnode spotlight
				dome_layer.addnode spotlight.target
				deleteItem vert_list ((int)mesh_face[j])
			)
		)
	)
)

function F_CreateDome domeSeg domeRad domeDel =( -- Create Dome based on rollout input
	-- texture picker
	setINIsetting (getmaxinifile()) "MAXHistoryList" "History_00" (getFilenamePath(getSourceFileName()))
	color_texture = selectBitMap ()
	if color_texture == undefined do (return())	-- returns if no texture was selected
	
	-- Dome creation
	dome = GeoSphere()
	select dome
	dome.segments = domeSeg
	dome.radius = domeRad
	dome.hemisphere = true
	addModifier dome (UVWUnwrap())
	dome.modifiers[#Unwrap_UVW].setTVSubObjectMode 3
	dome.modifiers[#Unwrap_UVW].selectFacesByNode #{1..dome.numfaces} dome
	dome.modifiers[#Unwrap_UVW].unwrap2.ScaleSelectedXY 1 2 [0,1,0]
	convertToMesh dome
	deletevert dome (getNumVerts dome)
	meshop.flipNormals dome #{1..dome.numfaces}
	dome.backfacecull = true
	dome.castShadows = false
	dome.receiveshadows = false
	update dome
	
	
	-- Material setup
	dome_mat = PhysicalMaterial()
	dome_mat.name = "Light Dome Material"
	dome_mat.base_color = white
	dome_mat.roughness = 1
	dome_mat.base_color_map = bitmapTexture filename:color_texture.filename
	dome_mat.emission_color_map = bitmapTexture filename:color_texture.filename	
	dome.material = dome_mat
	
	-- Create spotlights
	F_CreateSpotlights dome
	
	if domeDel do (delete dome)
)

rollout light_dome_rollout "Light Dome" (
	--(	Define UI
	label lbl_segments "Segments:" pos:[5,5]
	spinner spn_segments "" range:[1,10,1] type:#integer pos:[50,5] width:95
	label lbl_radius "Radius:" pos:[5,25]
	spinner spn_radius "" range:[0,1000,90] pos:[50,25] width:95
	checkbox chk_delete_dome "Delete Dome" pos:[35,45] tooltip:"Delete dome after lights are placed"
	button btn_create "Create Light Dome" pos:[5,65] width:140 height:50
	spinner spn_multiplier "Light Intensity" range:[0,1000,1] controller:SLD_light_controller pos:[5,130] enabled:false
	--)
	
	on btn_create pressed do (
		F_CreateDome spn_segments.value spn_radius.value chk_delete_dome.checked
		spn_multiplier.enabled = true
	)
)
CreateDialog light_dome_rollout 150 155