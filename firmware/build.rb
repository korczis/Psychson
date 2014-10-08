#! /usr/bin/env ruby

require 'fileutils'
require 'pathname'
require 'pp'

def build
	rel_files = []

	input_files = File.join(File.dirname(__FILE__), '*.c')
	bin_dir = File.join(File.dirname(__FILE__), '..', 'bin')
	FileUtils.mkdir_p bin_dir
	
	Dir[input_files].each do |f|
		p = Pathname.new f
		
		# Construct output path
		output_path = "#{bin_dir}/#{p.basename('.c')}.rel"
		
		# Add to list of rel files
		rel_files << output_path

		# Construct command
		cmd = "sdcc --model-small -mmcs51 -pdefcpu -c -o#{output_path} #{f}"
		puts cmd

		# Execute command
		system cmd
	end

	# Combine rel files
	input_files = rel_files.join(' ')
	output_hex = "#{bin_dir}/output.hex"
	output_bin = "#{bin_dir}/output.bin"
	cmd = "sdcc --xram-loc 0x6000 -o #{output_hex} #{input_files}"
	puts cmd
	system cmd

	# make binary
	cmd = "makebin -p #{output_hex} #{output_bin}"
	puts cmd
	system cmd
 
 	# Process templates
 	input_file = File.join(File.dirname(__FILE__), '..', 'templates', 'FWdummy.bin')
 	output_fw_file = File.join(bin_dir, 'fw.bin')
 	FileUtils.cp(input_file, output_fw_file)

 	input_file = File.join(File.dirname(__FILE__), '..', 'templates', 'BNdummy.bin')
 	output_bn_file = File.join(bin_dir, 'bn.bin')
 	FileUtils.cp(input_file, output_bn_file)

 	sfk_path = File.join(File.dirname(__FILE__), '..', 'tools', 'sfk')
	cmd = "#{sfk_path} partcopy #{output_bin} -fromto 0 -1 #{output_fw_file} 512 -yes"
	puts cmd
	system cmd

	cmd = "#{sfk_path} partcopy #{output_bin} -fromto 0 -1 #{output_bn_file} 512 -yes"
	puts cmd
	system cmd
end

if __FILE__ == $PROGRAM_NAME
	build
end

