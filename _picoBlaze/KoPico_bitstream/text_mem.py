#!/usr/bin/env python
import os
import sys
import string
from optparse import OptionParser

#convert decimal i (for range 0-256) to hex
def conver_to_hex(i):
	if i==0:
		ret='00'
	#if i is less than 16 hex(i) will return only one sign (0-F)
	#extra 0 have to be added to keep 0x00 format
	elif i<16:
		ret='0%s'%(hex(i).lstrip('0x'))
	else:
		ret=(hex(i).lstrip('0x'))
	return ret

usage = "usage: %prog [options]"
parser = OptionParser(usage)
parser.add_option("-n", "--name", action="store", type="string", dest="fname", help="Input file name")
parser.add_option("-b", "--bigend", action="store_true", dest="bigEndian", help="Use Big Endian")
(options, args) = parser.parse_args()

if options.fname:
	#get input file name
	fname=options.fname
	#try to remove old results files
	try:
		os.remove('%s.mem'%(fname.split('.')[0]))
		os.remove('%s.psm'%(fname.split('.')[0]))
	except OSError:
		pass
	#open file and declare tables for:
	fin = open(fname, 'r')
	#bytes which will be written into memory
	codes=[]
	#start adress of text/data entry
	adress=[]
	#variable names
	name=[]
	#current line under parsing
	line=0
	
	#parse input file
	for i in fin:
		line+=1
		i=i.rstrip()
		linetext=i
		#ommit empty line
		if i== "":
			continue
		#if line is comment (starts with ';') add it to variables list
		#and mark as comment in adress list by putting non existing address '-1'
		if i[0]== ";":
			name.append('%s\n'%i)
			adress.append('-1')
		#':' is used to separate variable name and data
		#ommit and display warning if line does not contain ':'
		elif not (':' in i):
			print 'WARNING: line %d \'%s\' does not contain \':\'!'%(line,linetext)
			continue
		else:
			#split line and check if variable name is not duplicated 
			i=i.split(':')
			if i[0] in name:
				print 'ERR: Duplicated name \'%s\'!'%i[0]
				sys.exit(1)
			else:
				#add variable name to list
				name.append(i[0])
			#join rest of line previously splitted by ':' - text may contain it
			i=':'.join(i[1:])
			#get data type:
			#		':s ' for string
			#		':b ' for bytes
			#		':w ' for words
			dtype=i[0]
			#remove data type and one space which should be added before data 
			i=i[2:]
			#if data is string:
			if dtype=='s':
				#write start address = number of bytes previously stored in codes table
				adress.append(hex(len(codes)).lstrip('0x'))
				#convert all chars in text into ascii codes and store it into bytes table
				for j in i:
					codes.append(hex(ord(j)).lstrip('0x'))
				#end text by adding zero value
				codes.append('00')
				i=''
			#if data is byte or word
			elif dtype=='b' or dtype=='w':
				#numeric data line should not contain any ':' 
				if ':' in i:
					print 'ERR: Syntax error in line %d \'%s\'!'%(line,linetext)
					sys.exit(1)
				#numeric data should be separated by space
				numdata=(i.strip()).split(' ')
				#write start address = number of bytes previously stored in codes table
				adress.append(hex(len(codes)).lstrip('0x'))
				#calculate data length in bytes:
				if dtype=='b':
					#for bytes = number of data in line
					adress.append(hex(len(numdata)).lstrip('0x'))
				else:
					#for words = 2 * number of data in line
					adress.append(hex(2*len(numdata)).lstrip('0x'))
				#add new variable name for data length:
				name.append('%s_length'%name[-1])
				#convert data formats into hex:
				#		data formats in input file
				#		$xx 			for hex
				#		%xxxxxxxx	for binary
				#		xxxxx			for decimal
				for j in numdata:
					#hex
					if j[0]=='$':
						#remove '$' and check if it's correct hex value
						k=j.split('$')[1]
						try:
							l=int('0x%s'%k,16)
						except ValueError:
							print 'ERR: $%s in line %d is not a valid hex number!'%(k,line)
							sys.exit(1)
						k=l
					#binary
					elif j[0]=='%':
						#remove '%' and check if it's correct binary value
						k=j.split('%')[1]
						try:
							l=int('0b%s'%k,2)
						except ValueError:
							print 'ERR: $%s in line %d is not a valid binary number!'%(k,line)
							sys.exit(1)
						k=l
					#decimal
					else:
						#check if it's correct integer value
						try:
							k=int(j)
						except ValueError:
							print 'ERR: %s in line %d is not a integer!'%(j,line)
							sys.exit(1)
					
					#check if parsed value is in range of declared data format
					#		0-255 for binary, 0-65535 for word
					if dtype=='b':
						if k<0 or k>255:
							print 'ERR: %d in line %d is out of byte range!'%(k,line)
							sys.exit(1)
						else:
							#convert int to hex and store it into bytes table
							codes.append(conver_to_hex(k))
					else:
						if k<0 or k>65535:
							print 'ERR: %d in line %d is out of word (16bit) range!'%(k,line)
							sys.exit(1)
						else:
							#convert int to hex depending on coding scheme:
							#if Big Endian option is used firstly write MSb, then LSb
							if options.bigEndian:
								codes.append(conver_to_hex(k/256))
								codes.append(conver_to_hex(k%256))
							#else use (default) Little Endian writting LSb first
							else:
								codes.append(conver_to_hex(k%256))
								codes.append(conver_to_hex(k/256))
			#unknown data type after colon (not s, b or w)
			else:
				print 'ERR: unknown data type \'%s\' in line %d!'%(dtype,line) 
				sys.exit(1)

	#number of bytes stored into ram should be even
	#add dummy zero value if is odd
	if len(codes)%2==1:
		codes.append('00')

	#prepare table for mem file filled with zeros
	mem=[]
	for i in range(5*256):
		mem.append('0000')

	#write to mem file all values stored into codes table
	#in "xilinx" format '0(n+1 byte)(n byte)'
	for j in range(0,len(codes),2):
		mem[j/2]='%s%s'%(codes[j],codes[j+1])
	
	#open output files - mem for memory contents
	fout = open('%s.mem'%(fname.split('.')[0]), 'w')
	
	
	#write mem file starting with address zero
	fout.write('@0000')
	for j in range(3*256):
		fout.write(' '+mem[j])
		#print mem[j]
		#start new line every 32 bytes
		if (j+1)%16==0:
			fout.write('\n')
			#print j, mem[j]
	fout.close()
	
	#and psm file for variables names and address
	foutadd = open('%s.psm'%(fname.split('.')[0]), 'w')
	#write psm file
	for i in range(len(adress)):
		#if address is equal '-1' variables name table contain only comment
		if adress[i]=='-1':
			foutadd.write(name[i])
		else:
			#hex(0) returns empty string so first address have to be fill with '00'
			if adress[i]=='':
				adress[i]='00'
			#if i is less than 16 hex(i) will return only one sign (0-F)
			#extra 0 have to be added to keep 0x00 format 
			if len(adress[i])==1:
				adress[i]='0%s'%adress[i]
			#write line "'variable name' EQU 'address'"
			foutadd.write('%s EQU $%s\n'%(name[i],adress[i]))
	#close all files
	fin.close()
	
	foutadd.close()
	print 'File %s parsed succesfully!'%fname
	
else:
	print 'ERR: No input file specified - nothing to do!'
