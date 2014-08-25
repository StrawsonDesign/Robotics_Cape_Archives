// calibrate_gyro.c
// James Strawson - 2014

// This routine samples the gyro for a second and saves a .cal file containing the offsets

#include <robotics_cape.h>
#define SAMPLE_RATE_HZ	200  //can go as high as 200

int  sum_x,sum_y,sum_z,samples;

int sample_imu_data(){
	mpudata_t mpu; //struct to read IMU data into
	memset(&mpu, 0, sizeof(mpudata_t)); //make sure it's clean before starting
	if (mpu9150_read(&mpu) == 0) {
		sum_x += mpu.rawGyro[VEC3_X];
		sum_y += mpu.rawGyro[VEC3_Y]; 
		sum_z += mpu.rawGyro[VEC3_Z];
		samples ++;
		fflush(stdout);
	}
	return 0; 
}

int main(){
	initialize_cape();
	
	printf("\nThis program will generate a new gyro calibration file\n");
	printf("keep your beaglebone very still and hit enter to calibrate\n");
	while( getchar() != '\n' );
	
	//start up the IMU
	signed char orientation[9] = ORIENTATION_UPRIGHT; //could also use ORIENTATION_FLAT
	initialize_imu(200,orientation);

	setXGyroOffset(0); //make sure gyro is zero'd first
	setYGyroOffset(0);
	setZGyroOffset(0);

	set_imu_interrupt_func(&sample_imu_data); //start the interrupt handler
	sleep(1);//sample for a second
	set_imu_interrupt_func(&null_func); //stop sampling data
	int fd;
	fd = open(GYRO_CAL_FILE, O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
	if (fd < 0) {
		printf("\n error opening gyro calibration file for writing\n");
		return -1;
	}
	char buff[64];
	printf("samples taken: %d\n", samples);
	int xoffset = (int16_t)round( 2.0*sum_z/samples);//actually x offset, DMP reverses x&z
	int yoffset = (int16_t)round(-2.0*sum_y/samples);
	int zoffset = (int16_t)round(-2.0*sum_x/samples);
	printf("new offsets: X: %d  Y: %d  Z: %d\n", xoffset,yoffset,zoffset);
	sprintf(buff, "%d\n%d\n%d\n",  xoffset, yoffset, zoffset); 
	write(fd, buff, strlen(buff));
	close(fd);
	printf("\ngyro calibration file written\n");
	printf("run test_imu to check performance\n");
		
	cleanup_cape();
	return 0;
}
