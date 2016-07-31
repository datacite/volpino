class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :aws

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "images/#{model.class.to_s.underscore}s"
  end

  # Process files as they are uploaded:
  process resize_to_fit: [500, 200]
  process convert: 'png'

  # Create different versions of your uploaded files:
  version :thumb do
    process resize_to_fit: [200, 80]
    process convert: 'png'
  end

  # Add a white list of extensions which are allowed to be uploaded.
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Only accept images
  def content_type_whitelist
    /image\//
  end

  # Override the filename of the uploaded files:
  def filename
    "#{model.name.downcase}.png" if original_filename
  end
end
