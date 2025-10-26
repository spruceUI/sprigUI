
import os
import shutil
import subprocess
from utils.image_utils import ImageUtils
from utils.logger import PyUiLogger


class FfmpegImageUtils(ImageUtils):

    def convert_from_jpg_to_png(self,jpg_path, png_path):
        """Convert a JPG image to PNG using ffmpeg."""
        try:
            subprocess.run([
                "ffmpeg",
                "-y",           # overwrite if exists
                "-i", jpg_path,
                png_path
            ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except subprocess.CalledProcessError as e:
            PyUiLogger().get_logger().error(f"Error converting {jpg_path} to {png_path}: {e}")

    def shrink_image_if_needed(self,input_path, output_path, max_width, max_height):
        temp_path = output_path + ".tmp.png"
        
        scale_filter = f"scale='min({max_width},iw)':'min({max_height},ih)':force_original_aspect_ratio=decrease"
        try:
            subprocess.run([
                "ffmpeg",
                "-y",
                "-i", input_path,
                "-vf", scale_filter,
                temp_path
            ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            # Replace original file
            shutil.move(temp_path, output_path)
            PyUiLogger().get_logger().info(f"Scaled: {input_path} → {output_path} within {max_width}x{max_height}")
        except subprocess.CalledProcessError as e:
            PyUiLogger().get_logger().error(f"Error resizing {input_path}: {e}")
            # Clean up temp file if it exists
            if os.path.exists(temp_path):
                os.remove(temp_path)
    def resize_image(self,input_path, output_path, max_width, max_height):
        """Resize the image to fit within max_width/max_height preserving aspect ratio using ffmpeg."""
        # This is essentially the same as shrink_image_if_needed
        self.shrink_image_if_needed(input_path, output_path, max_width, max_height)


    def get_image_dimensions(self,path):
        """
        Get image width and height using ffmpeg only (no ffprobe).
        Returns (width, height) or (0,0) on failure.
        """
        try:
            # Run ffmpeg in quiet mode, output info about first frame
            cmd = [
                "ffmpeg",
                "-i", path,
                "-v", "error",
                "-select_streams", "v:0",
                "-show_entries", "stream=width,height",
                "-of", "csv=p=0:s=x"
            ]
            # Actually, the above is ffprobe syntax. For pure ffmpeg we need another trick:
            cmd = ["ffmpeg", "-i", path]
            result = subprocess.run(cmd, capture_output=True, text=True)
            stderr = result.stderr

            # ffmpeg prints something like: Stream #0:0: Video: png, 800x600, ...
            import re
            m = re.search(r"Video:.* (\d+)x(\d+)", stderr)
            if m:
                width = int(m.group(1))
                height = int(m.group(2))
                return width, height
            return 0, 0
        except Exception as e:
            PyUiLogger().get_logger().info(f"Error getting dimens of {path} : {e}")
            return 0, 0

