// Import OGL components as ES module
import {
    Renderer,
    Geometry,
    Program,
    Mesh,
    Vec2,
    Vec4,
    Texture,
    Flowmap
} from 'https://esm.sh/ogl@1.0.11/es2022/ogl.mjs';

// Flowmap deformation effect
function flowmap_deformation() {
    document.querySelectorAll('.flowmap-deformation-wrapper').forEach(function(box) {
        const imgSize = [
            parseInt(box.getAttribute('data-bg-width')),
            parseInt(box.getAttribute('data-bg-height'))
        ];

        const vertex = `
            attribute vec2 uv;
            attribute vec2 position;
            varying vec2 vUv;
            void main() {
                vUv = uv;
                gl_Position = vec4(position, 0, 1);
            }
        `;

        const fragment = `
            precision highp float;
            precision highp int;
            uniform sampler2D tWater;
            uniform sampler2D tFlow;
            uniform float uTime;
            varying vec2 vUv;
            uniform vec4 res;

            void main() {
                // R and G values are velocity in the x and y direction
                // B value is the velocity length
                vec3 flow = texture2D(tFlow, vUv).rgb;

                vec2 uv = .5 * gl_FragCoord.xy / res.xy ;
                vec2 myUV = (uv - vec2(0.5))*res.zw + vec2(0.5);
                myUV -= flow.xy * (0.15 * 0.7);

                vec3 tex = texture2D(tWater, myUV).rgb;

                gl_FragColor = vec4(tex.r, tex.g, tex.b, 1.0);
            }
        `;

        // Use pre-existing canvas instead of creating new one
        const existingCanvas = box.querySelector('canvas');
        if (!existingCanvas) {
            console.error('Canvas not found in flowmap wrapper');
            return;
        }

        const renderer = new Renderer({ 
            dpr: 2,
            canvas: existingCanvas
        });
        const gl = renderer.gl;

        let aspect = 1;
        const mouse = new Vec2(-1);
        const velocity = new Vec2();

        function resize() {
            let a1, a2;
            var imageAspect = imgSize[1] / imgSize[0];
            if (box.offsetHeight / box.offsetWidth < imageAspect) {
                a1 = 1;
                a2 = box.offsetHeight / box.offsetWidth / imageAspect;
            } else {
                a1 = (box.offsetWidth / box.offsetHeight) * imageAspect;
                a2 = 1;
            }
            mesh.program.uniforms.res.value = new Vec4(box.offsetWidth, box.offsetHeight, a1, a2);
            renderer.setSize(box.offsetWidth, box.offsetHeight);
            aspect = box.offsetWidth / box.offsetHeight;
        }

        const flowmap = new Flowmap(gl, { 
            falloff: 0.6,
            dissipation: 0.96
        });

        const geometry = new Geometry(gl, {
            position: {
                size: 2,
                data: new Float32Array([-1, -1, 3, -1, -1, 3])
            },
            uv: {
                size: 2,
                data: new Float32Array([0, 0, 2, 0, 0, 2])
            }
        });

        const texture = new Texture(gl, {
            minFilter: gl.LINEAR,
            magFilter: gl.LINEAR
        });

        const img = new Image();
        img.onload = () => {
            texture.image = img;
            // Force initial render to load texture into GPU
            renderer.render({ scene: mesh });
            // Double RAF ensures GPU has processed the texture
            requestAnimationFrame(() => {
                requestAnimationFrame(() => {
                    box.classList.add('active');
                });
            });
        };
        img.crossOrigin = "Anonymous";
        img.src = box.getAttribute('data-bg');

        let a1, a2;
        var imageAspect = imgSize[1] / imgSize[0];
        if (box.offsetHeight / box.offsetWidth < imageAspect) {
            a1 = 1;
            a2 = box.offsetHeight / box.offsetWidth / imageAspect;
        } else {
            a1 = (box.offsetWidth / box.offsetHeight) * imageAspect;
            a2 = 1;
        }

        const program = new Program(gl, {
            vertex,
            fragment,
            uniforms: {
                uTime: { value: 0 },
                tWater: { value: texture },
                res: {
                    value: new Vec4(box.offsetWidth, box.offsetHeight, a1, a2)
                },
                img: {
                    value: new Vec2(imgSize[0], imgSize[1])
                },
                tFlow: flowmap.uniform
            }
        });

        const mesh = new Mesh(gl, { geometry, program });

        window.addEventListener("resize", resize, false);
        resize();

        const isTouchCapable = "ontouchstart" in window;
        const section = box.closest('section') || box.closest('.e-con');

        if (isTouchCapable) {
            section.addEventListener("touchstart", updateMouse, false);
            section.addEventListener("touchmove", updateMouse, { passive: false });
        } else {
            section.addEventListener("mousemove", updateMouse, false);
        }

        let lastTime;
        const lastMouse = new Vec2();

        function updateMouse(e) {
            if (e.changedTouches && e.changedTouches.length) {
                e.x = e.changedTouches[0].pageX;
                e.y = e.changedTouches[0].pageY;
            }
            if (e.x === undefined) {
                e.x = e.pageX;
                e.y = e.pageY;
            }
            mouse.set(e.x / gl.renderer.width, 1.0 - e.y / gl.renderer.height);

            if (!lastTime) {
                lastTime = performance.now();
                lastMouse.set(e.x, e.y);
            }

            const deltaX = e.x - lastMouse.x;
            const deltaY = e.y - lastMouse.y;
            lastMouse.set(e.x, e.y);

            let time = performance.now();
            let delta = Math.max(10.4, time - lastTime);
            lastTime = time;

            velocity.x = deltaX / delta;
            velocity.y = deltaY / delta;
            velocity.needsUpdate = true;
        }

        requestAnimationFrame(update);

        function update(t) {
            requestAnimationFrame(update);

            if (!velocity.needsUpdate) {
                mouse.set(-1);
                velocity.set(0);
            }
            velocity.needsUpdate = false;

            flowmap.aspect = aspect;
            flowmap.mouse.copy(mouse);
            flowmap.velocity.lerp(velocity, velocity.len ? 0.15 : 0.1);
            flowmap.update();

            program.uniforms.uTime.value = t * 0.01;
            renderer.render({ scene: mesh });
        }
    });
}

// Initialize flowmap on page load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}

function init() {
    // Wrapper and canvas already exist in HTML, just initialize
    const wrapper = document.querySelector('.flowmap-deformation-wrapper');
    
    if (wrapper) {
        flowmap_deformation();
    }
}