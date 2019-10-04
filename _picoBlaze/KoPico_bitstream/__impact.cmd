setMode -bs
# setCable -port auto
setCable -port usb21 -baud 12000000
Identify -inferir 
identifyMPM 
assignFile -p 1 -file BIT_NAME.bit
Program -p 1 
quit


# Cable baud rates
# 9.600
# 19.200
# 38.400
# 57.600
# 200.000
# 625.000
# 750.000
# 1.250.000
# 1.500.000
# 2.500.000
# 3.000.000
# 5.000.000
# 6.000.000
# 12.000.000
# 24.000.000
