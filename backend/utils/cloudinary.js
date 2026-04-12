const cloudinary = require('cloudinary').v2;
const streamifier = require('streamifier');

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

/**
 * Upload image to Cloudinary from buffer
 * @param {Buffer} buffer - Image file buffer
 * @param {string} folder - Cloudinary folder path
 * @param {string} publicId - Optional public ID for the image
 * @returns {Promise<string>} - Cloudinary URL of uploaded image
 */
const uploadToCloudinary = async (buffer, folder = 'smartcanteen', publicId = null) => {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: folder,
        public_id: publicId,
        resource_type: 'auto',
        overwrite: true,
      },
      (error, result) => {
        if (error) {
          console.error('❌ Cloudinary upload error:', error);
          reject(error);
        } else {
          console.log(`✅ Cloudinary upload success: ${result.secure_url}`);
          resolve(result.secure_url);
        }
      }
    );

    // Convert buffer to stream and upload
    streamifier.createReadStream(buffer).pipe(stream);
  });
};

/**
 * Delete image from Cloudinary
 * @param {string} imageUrl - Cloudinary image URL
 * @returns {Promise<void>}
 */
const deleteFromCloudinary = async (imageUrl) => {
  try {
    if (!imageUrl || !imageUrl.includes('cloudinary')) {
      return; // Not a Cloudinary URL, skip deletion
    }

    // Extract public ID from URL
    // URL format: https://res.cloudinary.com/[cloud]/image/upload/[transformations]/[public_id]
    const urlParts = imageUrl.split('/');
    const publicIdWithExt = urlParts[urlParts.length - 1];
    const publicId = publicIdWithExt.split('.')[0];

    if (publicId) {
      await cloudinary.uploader.destroy(publicId);
      console.log(`✅ Cloudinary delete success: ${publicId}`);
    }
  } catch (error) {
    console.error('⚠️ Cloudinary delete error:', error);
    // Don't throw - deletion failure should not stop other operations
  }
};

module.exports = {
  uploadToCloudinary,
  deleteFromCloudinary,
};
