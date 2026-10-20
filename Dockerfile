FROM runpod/worker-comfyui:5.10.0-base

# Install official MOSS-Image custom node
RUN git clone --depth 1 https://github.com/OpenMOSS/MOSS-Image.git /tmp/MOSS-Image \
    && cp -r /tmp/MOSS-Image/comfyui/moss-image /comfyui/custom_nodes/moss-image \
    && rm -rf /tmp/MOSS-Image