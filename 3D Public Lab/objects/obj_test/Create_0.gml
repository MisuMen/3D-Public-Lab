
u3d_system();

camera = new u3d_camera("mainCamera");
u3d_camera_rotate(camera,0,20,3);

model = new u3d_model(working_directory + "");
//u3d_model_spawn(model,0,0,0,true);

////////////////////////////////////////////////////////////////////////////////////////////

light = new u3d_light("mainLight");
u3d_light_set(light,.45,.8,.35,c_white);

ambient = new u3d_ambient("mainAmbient");