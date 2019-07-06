require 'zlib'
require 'rubygems'
require 'fox16'
require 'find'
require_relative 'KEY_CORE.rb'
include Fox
def long(file)
	return file.read(4).unpack("V").join.to_i
end
def byte(file)
	return file.read(1).unpack("C").join.to_i
end
def main_satrt(file)
	$files=long(file)
	ver1=long(file)
	ver2=long(file)
	ver3=long(file)
	$mode=0
	if ver1 >= 1 and ver3 > 1
		$mode=1
	end
	info_size=28
	if $mode != 0
		info_size=40
	end
	puts "files:#{$files},ver1:#{ver1},ver2:#{ver2},ver3:#{ver3},mode:#{$mode},info_size:#{info_size}"
	file_table_off=long(file)
	file.seek(file_table_off)
	if FileTest.exist?($info_table_name)
		print $info_table_name,"is exsit!\n"
	else
		new_info_table=File.open($info_table_name,"wb")
		for i in 0..(($files*28)-1)
			un_data=byte(file)^$key_table[i]
			new_info_table.print [un_data].pack("C")
		end
		new_info_table.close
		puts "table save done!"
	end
end
def key_core
	$key_table=[]
	#key_file=File.open("key_info","rb")
	puts "key input!"
	#for i in 0..(key_file.size-1)
		#print "key read#{i}/#{key_file.size-1}"
		#$key_table[i]=byte(key_file)
		#system("cls")
	$key_table=KEY_CORE.get_key_table
	#end
	#system("cls")
	puts "key input done!"
	#key_file.close
end

def table_input
	table_file=File.open($info_table_name,"rb")
	$name_crc_table=[]
	$offset_table=[]
	$zsize_table=[]
	$sizee_table=[]
	$zflage_table=[]
	for ii in 0..($files-1)
		name_crc=long(table_file)
		offset=long(table_file)
		zsize=long(table_file)
		sizee=long(table_file)
		zcrc=long(table_file)
		crc=long(table_file)
		flags=long(table_file)
		#print "\n"
		zflags=flags&65535
		flags=flags>>16
		#print "name_crc:#{name_crc.to_s(16)},offset:#{offset},zsize:#{zsize},sizee:#{sizee},zflags:#{zflags},flags:#{flags}"
		$name_crc_table[$name_crc_table.size]=name_crc.to_s(16)
		$offset_table[$offset_table.size]=offset
		$sizee_table[$sizee_table.size]=sizee
		$zsize_table[$zsize_table.size]=zsize
		if zflags == 2
			#print ",comtype:lz4\n"
			$zflage_table[$zflage_table.size]="lz4"
		else
			$zflage_table[$zflage_table.size]="zlib"
			#print ",comtype:zlib\n"
		end
	end
	table_file.close
end
def xor_core(file,offset,size)
	file.seek(offset)
	tmp_dec_data=[]
	for i in 0..(size-1)
		tmp_dec_data[i]=[(byte(file)^$key_table[i])].pack("C")
	end
	return tmp_dec_data.join.to_s
end
def lname(data)
	if data.size == 0
		return ".none"
	end
	if data[0..11] == "CocosStudio-UI"
		return ".coc"
	end
	hstrr=data[0..3].unpack("C*")
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
def sub_file_dec(file)
	if File.directory?($floder_wz+"/"+$base_name)
	#	puts "floder:#{$base_name} is exist!"
	else
		Dir::mkdir($floder_wz+"/"+$base_name)
	end
	for i in 0..($files-1)
		puts "out file:#{i}/#{$files-1}"
		file_name=$floder_wz+"/"+$base_name+"/"+$name_crc_table[i]#0]
		offset=$offset_table[i]#0]
		sizee=$sizee_table[i]#0]
		zsize=$zsize_table[i]#0]
		zflag=$zflage_table[i]#0]
		if sizee >= 892640 or sizee < 5000;
			puts "next"
			next
		end
		print "#{offset.to_s(16)},#{sizee.to_s(16)}\n"
		if zflag == "zlib"
			tmp_sz=xor_core(file,offset,sizee)
			p=tmp_sz[0..1].unpack("C*")
			print p,"\n"
			if p == [120,156]
				zlib_dec_data=Zlib::Inflate.inflate(tmp_sz)
				last_name=lname(zlib_dec_data)
				tmp_file=File.open(file_name+last_name,"wb")
			else
				zlib_dec_data=tmp_sz
				last_name=".check.dat"
				tmp_file=File.open(file_name+last_name,"wb")
			end
			tmp_file.print zlib_dec_data
			tmp_file.close
			puts "save:#{file_name+last_name}"
		end
	end
end
def nexpk_main(file_name,floder_name)
	tmp_name=file_name.split("\\")
	tmp_name=tmp_name[(tmp_name.size)-1]
	$file_name=file_name
	$floder_wz=floder_name.split("\\").join("/").to_s
	$base_name=tmp_name.split(".")[0].to_s
	table_floder=file_name.split("\\").join("/").to_s.gsub(tmp_name,"")
	$info_table_name=table_floder+$base_name+".table"
	expk_file=File.open($file_name,"rb")
	if expk_file.read(4).to_s == "EXPK"
		#if FileTest.exist?($info_table_name)
		#else
			key_core
		#end
		#print $key_table
		main_satrt(expk_file)
		table_input
		sub_file_dec(expk_file)
	end
	print "done!"
end

class Vc_ui_window < FXMainWindow
	def initialize app
		super(app,'expk_pot',:opts=>DECOR_ALL,:width=>300,:height=>100)
		FXToolTip.new(self.getApp())#工具提示
		#状态栏
		statusbar=FXStatusBar.new(self,
		LAYOUT_SIDE_BOTTOM|
		LAYOUT_FILL_X|
		STATUSBAR_WITH_DRAGCORNER
		)
		#控制
		controls = FXVerticalFrame.new(self,
		LAYOUT_SIDE_RIGHT|
		LAYOUT_FILL_Y|
		PACK_UNIFORM_WIDTH
		)
		#分隔线
		FXVerticalSeparator.new(self,
		LAYOUT_FILL_X|#LAYOUT_SIDE_RIGHT|
		LAYOUT_SIDE_TOP|#LAYOUT_FILL_Y|
		SEPARATOR_GROOVE
		)
		contents=FXHorizontalFrame.new(self,
		LAYOUT_SIDE_LEFT|
		FRAME_NONE|
		LAYOUT_FILL_X|
		LAYOUT_FILL_Y|
		PACK_UNIFORM_WIDTH,
		:padding => 20)
		@button=FXButton.new(contents,
		"&sele.\t"+
		"sele.\t"+
		"sele",
		:opts=>FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_X|LAYOUT_CENTER_Y|LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT,
		:width=>80,
		:height=>40
		)
		@button.connect(SEL_COMMAND) do |sender,sel,checkend|
			if checkend
				puts "sele file"
				$glb_file = FXFileDialog.getSaveFilename(self, "Open file",
				"C:\WINDOWS\system32\cmd.exe")#__FILE__)
				puts $glb_file
				puts "sele folder"
				$glb_floder = FXFileDialog.getOpenDirectory(self, "Open file",
				"c:\\")#File.dirname(__FILE__))
				puts $glb_floder
			end
		end
		
		@button2=FXButton.new(contents,
		"&run.\t"+
		"run.\t"+
		"run",
		:opts=>FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_X|LAYOUT_CENTER_Y|LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT,
		:width=>80,
		:height=>40
		)
		@button2.connect(SEL_COMMAND) do |sender,sel,checkend|
			if checkend
				puts "run"
				if $glb_file != "" and $glb_floder != ""
					nexpk_main($glb_file,$glb_floder)
				else
					puts "please sele"
				end
			end
		end
		#checkButton=FXCheckButton.new(controls,
		#"no delete\t处理完成后不删除原文件?\t处理完成后不删除原文件?"
		#)
		#checkButton.connect(SEL_COMMAND) do |sender,sel,checkend|
		#	if checkend
		#		#puts "勾选"
		#		$dele_mode=false
		#	else
		#		#puts "未勾选"
		#		$dele_mode=true
		#	end
		#end
	end
	def create
		super
		show PLACEMENT_SCREEN
	end
end

if __FILE__ == $0
	#if (ARGV[0].to_s) == "1"
		$glb_floder=""
		$glb_file=""
		app=FXApp.new('expk_pot','expk_pot')
		main_window=Vc_ui_window.new(app)
		#print("yes")
		app.create
		app.run
	#end
end