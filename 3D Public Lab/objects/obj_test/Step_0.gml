u3d_camera_position(camera,0,1,0);
u3d_camera_mouselook(camera,mouse_check_button(mb_right),16);
//u3d_camera_rotate(camera,current_time/60,20,3);
u3d_camera_set_view(camera);
u3d_update();