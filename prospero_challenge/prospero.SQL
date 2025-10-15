/* 
1. define the image size, 128 
2. from -1 to 1, evenly distribute the 128 numbers
3. generate a panel, from (-1,-1) to (1,1), total points is 128*128 
4. for each point in the panel, assign the value, based on the calculation on step 2 
   4.1 from left to right, the number is -1 to 1 
   4.2 from up to down, the number is 1 to -1
   4.3 for each point, there should be 2 numbers, one is from X-axis, one is from Y-axis. These 2 numbers will be used for calculation later
5. for each point in the panel, go through the prospero instruction, get the result
6. generate the final output
*/


















