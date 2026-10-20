FROM runpod/worker-comfyui:5.10.0-base

# Install the official MOSS-Image ComfyUI custom node without downloading
# model weights into the image.
RUN git clone --depth 1 https://github.com/OpenMOSS/MOSS-Image.git /tmp/MOSS-Image \
    && install -d /comfyui/custom_nodes/moss-image \
    && cp -a /tmp/MOSS-Image/comfyui/moss-image/. /comfyui/custom_nodes/moss-image/ \
    && rm -rf /tmp/MOSS-Image

# Resolve the RunPod Serverless cached model before handing control to the
# base image startup script.
COPY start-moss.sh /usr/local/bin/start-moss.sh
RUN chmod +x /usr/local/bin/start-moss.sh

# Preserve the base image ENTRYPOINT (if present); the wrapper execs the
# original RunPod /start.sh after validating the cached model.
CMD ["/usr/local/bin/start-moss.sh"]