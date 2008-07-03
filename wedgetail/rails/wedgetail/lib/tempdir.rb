require 'tmpdir'

# module for temporoary directory handling
module Tempdir
  # return a suitable temporary directory. Make sure it exists. Uses the 
  # process ID to guarantee uniqueness
  def self.tmpdir
    tmpdir_name = Dir::tmpdir + '/wedg'+Process.pid.to_s+'/'
    if ! File.exists? tmpdir_name
      Dir.mkdir tmpdir_name
    end
    tmpdir_name
  end

  # enter the temporary directory, return at the end of the block
  def self.ensure_tmpdir(&blk)
    Dir.chdir(Tempdir.tmpdir,&blk)
  end
end