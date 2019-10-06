require 'zlib'
require_relative 'KEY_CORE.rb'
def lname(data)
	if data.size == 0
		return ".none"
	end
	if data[0..11] == "CocosStudio-UI"
		return ".coc"
	end
	hstrr=data[0..3].unpack("C*")
	#print data[0],"\n"
	if data[0] == "<"
		return ".xml"
	elsif data[0] == "{"
		return ".json"
	elsif data[0..2] == "hit"
		return ".hit"
	elsif data[0..2] == "PKM"
		return ".pkm"
	elsif data[0..2] == "PVR"
		return ".pvr"
	elsif data[0..2] == "DDS"
		return ".dds"
	elsif data[1..3] == "KTX"
		return ".ktx"
	elsif data[1..3] == "PNG"
		return ".png"
	elsif hstrr == [52,128,200,187]#3480c8bb
		return ".nxm"
	elsif data[0..3] == [20,0,0,0]#14000000
		return ".type1"
	elsif data[0..3] == [4,0,0,0]#04000000
		return ".type2"
	elsif data[0..3] == [0,1,0,0]#00010000
		return ".type3"
	elsif data[0..3] == "VANT"
		return ".vant"
	elsif data[0..3] == "MDMP"
		return ".mdmp"
	elsif data[0..3] == "RGIS"
		return ".rgis"
	elsif data[0..3] == "NTRK"
		return ".ntrk"
	elsif data.size < 1000000
		if data.include?"void" or data.include?"main("
			return ".shader"
		end
		if data.include?"include" or data.include?"float"
			return ".shader"
		end
		if data.include?"technique" or data.include?"ifndef"
			return ".shader"
		end
		if data.include?"?xml"
			return ".xml"
		end
		if data.include?"import"
			return ".py"
		end
		if data.include?"1000" or data.include?"ssh"
			return ".txt"
		end
		if data.include?"png" or data.include?"tga"
			return ".txt"
		end
		if data.include?"exit"
			return ".txt"
		end
	end
	return ".dat"
end
def long
	return $expk.read(4).unpack("V").join.to_i
end
def byte
	return $expk.read(1).unpack("C").join.to_i
end
def goto(wz)
	$expk.seek(wz)
end
def dec_long
	p=[0,0,0,0]
	for a in 0...4
		p[a]=[byte^$key_table[$info_table_js]].pack("C")
		$info_table_js+=1
	end
	return p.join.to_s.unpack("V")[0]
end
$key_table=[]
$key_table=KEY_CORE.get_key_table

$info_table_js=0
$file_block_js=0

$expk=File.open(ARGV[0],"rb")
$base_name=ARGV[0].to_s.split(".")[0]
found_file=ARGV[1]
if $expk.read(4).to_s == "EXPK"
	$files=long
	ver1,ver2,ver3,info_table_offset=long,long,long,long
	#mode=1 #if ver1 and ver3 else 0
	goto(info_table_offset)
	if File.directory?($base_name)
	else
		Dir::mkdir($base_name)
	end
	if File.directory?($base_name+"_other")
	else
		Dir::mkdir($base_name+"_other")
	end
	for i in 0...$files
		system("cls")
		print "#{i+1}\\#{$files}\n"
		$file_block_js=0
		name_crc,offset=dec_long,dec_long
		f_size,f_zsize=dec_long,dec_long
		zcrc,crc,zflag=dec_long,dec_long,dec_long&65535
		print [name_crc.to_s(16),f_size,f_zsize],"\n"
		mq_wz=$expk.pos
		goto(offset)
		r_data=$expk.read(f_size)
		#print Zlib.crc32(r_data).to_s(16)
		if f_size <= 892640 or f_size > 5000
			dec_data=[]
			for a in 0...f_size
				dec_data[a]=[r_data[a].unpack("C")[0]^$key_table[$file_block_js]].pack("C")
				$file_block_js+=1
			end
			dec_data=dec_data.join.to_s
			if zflag != 2
			#zlib
				p=dec_data[0..1].unpack("C*")
				case p
				when [120,1]
					un_dec_data=Zlib::Inflate.inflate(dec_data)
					last_name=".Loun.zlib"+lname(un_dec_data)
				when [120,156]
					un_dec_data=Zlib::Inflate.inflate(dec_data)
					last_name=".Deun.zlib"+lname(un_dec_data)
				when [120,218]
					un_dec_data=Zlib::Inflate.inflate(dec_data)
					last_name=".Beun.zlib"+lname(un_dec_data)
				else
					un_dec_data=dec_data
					last_name=".noun.zlib.dat"
				end
				
			else
			#lz4
				un_dec_data=dec_data
				last_name=".noun.lz4.dat"
			end
			#save file
			file_name=$base_name+"/"+(name_crc.to_s(16))+last_name
			if FileTest.exist?(file_name)
			else
				n_p=File.open(file_name,"wb")
				n_p.print un_dec_data
				n_p.close
			end
		else
			dec_data=[]
			if f_size > 892640
				dec_data=r_data
				file_name=$base_name+"_other/"+(name_crc.to_s(16))+".high.dat"
			elsif f_size <= 892640
				dec_data=[]
				for a in 0...f_size
					dec_data[a]=[r_data[a].unpack("C")[0]^$key_table[$file_block_js]].pack("C")
					$file_block_js+=1
				end
				dec_data=dec_data.join.to_s
				file_name=$base_name+"_other/"+(name_crc.to_s(16))+".low.dat"
			end
			if FileTest.exist?(file_name)
			else
				
				n_p=File.open(file_name,"wb")
				n_p.print dec_data
				n_p.close
			end
		end
		print file_name,"\n"
		goto(mq_wz)
		if name_crc.to_s(16) == found_file.to_s
			break
		end
	end
end