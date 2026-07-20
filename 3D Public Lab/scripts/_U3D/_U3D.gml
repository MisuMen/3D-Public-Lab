global.__U3D = undefined;

#macro DELTA (delta_time * 0.000001)

function u3d_system(_obj=self) {
	
	assets = [];
	renderer =  new GM3D_Renderer();
	scene = GM3D_Scene.createEmpty();
	
	global.__U3D = _obj;
}

function u3d_clear() {
	scene.destroy();
	scene = undefined;

	// Destroy all loaded source scenes
	for (var i = 0; i < array_length(assets); ++i) { assets[i].destroy(); }
	assets = [];

	// Release renderer ownership
	renderer = undefined;
}

function u3d_update() {
	scene.update(DELTA);
}

function u3d_render() {
	renderer.render(scene);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
function u3d_pointer(_node,_dire) {
	var _forward = _dire.clone();
	_forward.normalize();

	var _up = GM3D_Vec3.up();
	if (abs(_forward.dot(_up)) >= 0.999)
	{
		_up = GM3D_Vec3.forward();
	}

	var _rotation = GM3D_Quaternion.fromLookRotation(_forward, _up);
	_node.setLocalRotation(_rotation.normalizeSafe(0.000001));
}
	
function u3d_shaders(_scene, _instanced = false) {
	var _nodes = _scene.getNodes();
	var _materials = _scene.getMaterials();

	var _staticShader = _instanced ? shStaticInstanced : shStatic;
	var _animatedShader = _instanced ? shAnimatedInstanced : shAnimated;

	// Assign static shader to all materials by default
	for (var _matIdx = 0; _matIdx < array_length(_materials); ++_matIdx)
	{
		var _material = _materials[_matIdx];
		_material.setShader(_staticShader);
	}

	// Override with animated shader for nodes with skinned mesh components
	for (var _nodeIdx = 0; _nodeIdx < array_length(_nodes); ++_nodeIdx)
	{
		var _node = _nodes[_nodeIdx];
		var _skinnedComp = _node.getSkinnedMeshComponent();
		if (_skinnedComp != undefined)
		{
			var _skinnedMat = _skinnedComp.getMaterial();
			if (_skinnedMat != undefined)
			{
				_skinnedMat.setShader(_animatedShader);
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
function u3d_camera(_name,_enable=true) constructor {
	x = 0;
	y = 0;
	z = 0;
	
	yaw = 180;
	pitch = 0;
	roll = 0;
	length = 1;
	
	hspeed = 0;
	vspeed = 0;
	fspeed = 0;
	
	xfriction = 0;
	yfriction = 0;
	
	node = global.__U3D.scene.createNode(_name);
	comp = new GM3D_CameraComponent();
	node.addComponent(comp);
	
	comp.setEnabled(_enable);
	comp.setNear(1.0);
	comp.setFar(10000.0);
	comp.setScreenRect([0.0, 0.0, 1.0, 1.0]);
}

function u3d_camera_set_view(_ind) {

	var _camX = _ind.x + dcos(_ind.yaw) * dcos(_ind.pitch) * _ind.length;
	var _camY = _ind.y + dtan(_ind.pitch) * dcos(_ind.pitch) * _ind.length;
	var _camZ = _ind.z + dsin(_ind.yaw) * dcos(_ind.pitch) * _ind.length;

	var _lookPos = new GM3D_Vec3(_ind.x,_ind.y,_ind.z);
	var _camPos = new GM3D_Vec3(_camX, _camY, _camZ);
	_ind.node.setLocalPosition(_camPos);

	var _lookDir = (new GM3D_Vec3()).subVectors(_camPos, _lookPos);
	u3d_pointer(_ind.node, _lookDir);
}

function u3d_camera_set_proj(_ind,_fov,_aspect,_near,_far,_rect=[0,0,1,1]) {
	_ind.comp.setFovY(_fov);
	_ind.comp.setAspectRatio(_aspect);
	_ind.comp.setNear(_near);
	_ind.comp.setFar(_far);
	_ind.comp.setScreenRect(_rect);
}

function u3d_camera_position(_ind,_x,_y,_z) {
	_ind.x = _x;
	_ind.y = _y;
	_ind.z = _z;
}

function u3d_camera_move(_ind,_speed,_tilt=true) {
	var angle = (_tilt ? dcos(_ind.pitch) : 1);
	var height = (_tilt ? dtan(_ind.pitch) : 0);
	_ind.hspeed = dcos(_ind.yaw) * angle * _speed;
	_ind.vspeed = height * angle * _speed;
	_ind.fspeed =-dsin(_ind.yaw) * angle * _speed;
}

function u3d_camera_rotate(_ind,_yaw,_pitch,_length) {
	_ind.yaw = _yaw;
	_ind.pitch = _pitch;
	_ind.length = _length;
}

function u3d_camera_mouselook(_ind,_enable,_speed,_sensitivity=.025,_friction=.75) {
	window_mouse_set_locked(_enable);
    
		if (window_mouse_get_locked()) {
			//center of the screen 
			var mx = window_mouse_get_delta_x();
			var my = window_mouse_get_delta_y();
 
			//If mouse position left center position, add length with sensitivity 
			if (mx != 0) { _ind.xfriction += mx * _sensitivity; }//sensitivity 
			if (my != 0) { _ind.yfriction += my * _sensitivity; } 
 
			//Keep values within speed range 
			_ind.xfriction = clamp( _ind.xfriction, -_speed, _speed);//speed 
			_ind.yfriction = clamp( _ind.yfriction, -_speed, _speed); 
 
			//Apply friction 
			_ind.xfriction *= _friction;//friction 
			_ind.yfriction *= _friction; 
 
			//final direction results 
			_ind.yaw = (_ind.yaw + _ind.xfriction) mod 360; 
			_ind.yaw = (_ind.yaw < 0 ? _ind.yaw + 360 : _ind.yaw);
			_ind.pitch = clamp(_ind.pitch + _ind.yfriction, -84, 84); 
		}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
function u3d_model(_file,_instanced=false) constructor {

	model = GM3D_Scene.loadGltf(_file);
	if (model == undefined) return undefined;

	index = 1;
	
	animate = false;
	
	animation = undefined;
	
	u3d_shaders(model,_instanced);
	model.freeze();
	array_push(global.__U3D.assets, model);
	
	////////////////////////////////////////////////////////////////
	static getAnimComp = function(_node) {
		if (_node == undefined) return undefined;

		var _directComp = _node.getAnimationComponent();
		if (_directComp != undefined) return _directComp;

		var _children = _node.getChildren();
		for (var i = 0; i < array_length(_children); ++i) {
			var _nestedComp = getAnimComp(_children[i]);
			if (_nestedComp != undefined) return _nestedComp;
		}

		return undefined;
	}
	
	static setAnimComp = function(_ind,_spd=1.) {
		var animCount = model.animationCount;
		if (animCount > 0) {
			var _anim = model.getAnimation(_ind);

			if (animation != undefined) {
				animation.setTime(0.0);
				animation.setSpeed(_spd);
				animation.play(_ind, animate);
			}
		}
	}
	
}

function u3d_model_animate(_model,_enable,_sub,_speed=1) {
	_model.animate = _enable;
	_model.setAnimComp(_sub,_speed);
}

function u3d_model_spawn(_model,_x,_y,_z,_animate=false) {
	_model.animate = _animate;
	var _root = _model.model.spawnInto(scene, undefined);
		_root.setLocalPosition(new GM3D_Vec3(_x, _y, _z));
		
	if _animate {
		_model.animation = _model.getAnimComp(_root);
		_model.setAnimComp(_model.index);
	}
	
	return _root;
}

function u3d_model_instance_position(_ind,_x,_y,_z) {
	_ind.setLocalPosition(new GM3D_Vec3(_x, _y, _z));
}

function u3d_model_instance_scale(_ind,_sx,_sy,_sz) {
	_ind.setLocalScale(new GM3D_Vec3(_sx, _sy, _sz));
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
function u3d_light(_str) constructor {
	
	node = global.__U3D.scene.createNode(_str);
	component = new GM3D_LightComponent();
	node.addComponent(component);
	
	component.setType(GM3D_ELightType.Directional);
	
	direction = new GM3D_Vec3(0.,0.,0.);
}

function u3d_light_set(_ind,_x,_y,_z,_color) {
	_ind.component.setColor(_color);
	
	_ind.direction = new GM3D_Vec3(_x,_y,_z);

	u3d_pointer(_ind.node, _ind.direction);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
function u3d_ambient(_str,_color=make_colour_rgb(80, 80, 100)) constructor {
	node = global.__U3D.scene.createNode(_str);
	component = new GM3D_EnvironmentVolumeComponent();
	node.addComponent(component);
	
	size = new GM3D_Vec3(20000.0, 20000.0, 20000.0);
	component.setSize(size.x, size.y, size.z);
	component.setAmbientColor(_color);
}

function u3d_ambient_color(_ind,_color) {
	_ind.component.setAmbientColor(_color);
}
	
function u3d_ambient_fog(_amb,_enable,_color,_near,_far) {
	_amb.component.setFogEnabled(_enable);
	_amb.component.setFogColor(_color);
	_amb.component.setFogStart(_near);
	_amb.component.setFogEnd(_far);
}