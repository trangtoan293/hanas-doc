import React, {useEffect, useMemo, useRef, useState} from 'react';
import {Html} from '@react-three/drei';
import {Canvas, useFrame} from '@react-three/fiber';
import {Bloom, EffectComposer, Vignette} from '@react-three/postprocessing';
import * as THREE from 'three';
import {journeySources, type JourneySource} from './journeyRecords';
import styles from './styles.module.css';

const PARTICLE_COUNT = 840;
// Bốn nguồn phải cách nhau đủ rộng để thẻ Hanas Capture ở giữa không đè lên thẻ nào.
const SOURCE_X = 2.62;
const SOURCE_Y = 1.98;
const SOURCE_CENTERS = [
  new THREE.Vector3(-SOURCE_X, SOURCE_Y, 0),
  new THREE.Vector3(SOURCE_X, SOURCE_Y, 0),
  new THREE.Vector3(-SOURCE_X, -SOURCE_Y, 0),
  new THREE.Vector3(SOURCE_X, -SOURCE_Y, 0),
];

interface JourneyCanvasProps {
  progressRef: {current: number};
}

interface SignalData {
  baseColors: Float32Array;
  colors: Float32Array;
  invalid: Uint8Array;
  modelPositions: Float32Array;
  outputPositions: Float32Array;
  phases: Float32Array;
  positions: Float32Array;
  rawPositions: Float32Array;
  sizes: Float32Array;
  sourceIndexes: Uint8Array;
}

function clamp01(value: number): number {
  return Math.min(1, Math.max(0, value));
}

function smoothstep(edge0: number, edge1: number, value: number): number {
  const progress = clamp01((value - edge0) / Math.max(edge1 - edge0, 0.0001));
  return progress * progress * (3 - 2 * progress);
}

function peak(progress: number, start: number, holdStart: number, holdEnd: number, end: number): number {
  return smoothstep(start, holdStart, progress) * (1 - smoothstep(holdEnd, end, progress));
}

// Cùng ngưỡng chương với index.tsx. Trước đây cảnh 3D đổi ở 0.25/0.5/0.75 còn chữ đổi ở
// 0.17/0.37/0.57 nên hai lớp lệch nhau — đó là chỗ thấy "đột ngột".
const STAGE_THRESHOLDS = [0.17, 0.37, 0.57, 0.77];
const STAGE_MORPH = 0.055;

// Tổng các smoothstep: phẳng ở giữa mỗi chương, chỉ biến đổi quanh ngưỡng.
function stageProgress(progress: number): number {
  return STAGE_THRESHOLDS.reduce(
    (total, threshold) => total + smoothstep(threshold - STAGE_MORPH, threshold + STAGE_MORPH, progress),
    0,
  );
}

function createSignalData(): SignalData {
  const positions = new Float32Array(PARTICLE_COUNT * 3);
  const colors = new Float32Array(PARTICLE_COUNT * 3);
  const rawPositions = new Float32Array(PARTICLE_COUNT * 3);
  const modelPositions = new Float32Array(PARTICLE_COUNT * 3);
  const outputPositions = new Float32Array(PARTICLE_COUNT * 3);
  const baseColors = new Float32Array(PARTICLE_COUNT * 3);
  const phases = new Float32Array(PARTICLE_COUNT);
  const sizes = new Float32Array(PARTICLE_COUNT);
  const sourceIndexes = new Uint8Array(PARTICLE_COUNT);
  const invalid = new Uint8Array(PARTICLE_COUNT);
  const palettes = [
    new THREE.Color('#78b8d8'),
    new THREE.Color('#94d9ce'),
    new THREE.Color('#d4a36e'),
    new THREE.Color('#b4c8d8'),
  ];

  let seed = 348921;
  const random = () => {
    seed = (seed * 1664525 + 1013904223) % 4294967296;
    return seed / 4294967296;
  };

  for (let index = 0; index < PARTICLE_COUNT; index += 1) {
    const offset = index * 3;
    const sourceIndex = index % SOURCE_CENTERS.length;
    const source = SOURCE_CENTERS[sourceIndex];
    const localIndex = Math.floor(index / SOURCE_CENTERS.length);
    const column = localIndex % 18;
    const row = Math.floor(localIndex / 18) % 10;
    const palette = palettes[sourceIndex];

    rawPositions[offset] = source.x + (column - 8.5) * 0.105 + (random() - 0.5) * 0.04;
    rawPositions[offset + 1] = source.y + (row - 4.5) * 0.09 + (random() - 0.5) * 0.035;
    rawPositions[offset + 2] = source.z + (random() - 0.5) * 0.12;

    // Chương 04 do sơ đồ ERD dạng DOM kể. Hạt từng vẽ 3 "bảng" ngay chỗ sơ đồ nên thành
    // khối chấm hình chữ nhật đè lên nội dung — giờ chuyển thành vành sáng lùi ra sau,
    // chừa trống phần giữa cho sơ đồ.
    const haloAngle = random() * Math.PI * 2;
    const haloRadius = 4.9 + random() * 2.3;
    modelPositions[offset] = Math.cos(haloAngle) * haloRadius;
    modelPositions[offset + 1] = Math.sin(haloAngle) * haloRadius * 0.66;
    modelPositions[offset + 2] = -2.3 - random() * 1.7;

    if (index < 600) {
      const bar = Math.floor(index / 50);
      const pointInBar = index % 50;
      const pointColumn = pointInBar % 5;
      const pointRow = Math.floor(pointInBar / 5);
      const height = 0.56 + ((bar * 7) % 10) * 0.12;
      outputPositions[offset] = -2.9 + bar * 0.5 + (pointColumn - 2) * 0.05;
      outputPositions[offset + 1] = -1.68 + pointRow * (height / 9);
      outputPositions[offset + 2] = (random() - 0.5) * 0.06;
    } else {
      const chartIndex = index - 600;
      const chartProgress = (chartIndex % 120) / 119;
      outputPositions[offset] = -3 + chartProgress * 6;
      outputPositions[offset + 1] = 0.5 + chartProgress * 1.12
        + Math.sin(chartProgress * Math.PI * 4) * 0.24
        + Math.floor(chartIndex / 120) * 0.08;
      outputPositions[offset + 2] = 0.1 + Math.floor(chartIndex / 120) * 0.05;
    }

    positions[offset] = rawPositions[offset];
    positions[offset + 1] = rawPositions[offset + 1];
    positions[offset + 2] = rawPositions[offset + 2];
    colors[offset] = palette.r;
    colors[offset + 1] = palette.g;
    colors[offset + 2] = palette.b;
    baseColors[offset] = palette.r;
    baseColors[offset + 1] = palette.g;
    baseColors[offset + 2] = palette.b;
    phases[index] = random();
    sizes[index] = 0.74 + random() * 0.92;
    sourceIndexes[index] = sourceIndex;
    invalid[index] = index % 19 === 0 || index % 37 === 0 ? 1 : 0;
  }

  return {
    baseColors,
    colors,
    invalid,
    modelPositions,
    outputPositions,
    phases,
    positions,
    rawPositions,
    sizes,
    sourceIndexes,
  };
}

const particleVertexShader = `
  attribute float aSize;
  attribute vec3 color;
  varying vec3 vColor;
  uniform float uPixelRatio;
  uniform float uPulse;

  void main() {
    vec4 viewPosition = modelViewMatrix * vec4(position, 1.0);
    float perspective = 48.0 / max(2.0, -viewPosition.z);
    vColor = color;
    gl_PointSize = aSize * uPixelRatio * perspective * (0.9 + uPulse * 0.12);
    gl_Position = projectionMatrix * viewPosition;
  }
`;

const particleFragmentShader = `
  varying vec3 vColor;
  uniform float uOpacity;

  void main() {
    float radius = distance(gl_PointCoord, vec2(0.5));
    float halo = smoothstep(0.5, 0.06, radius);
    float core = smoothstep(0.16, 0.0, radius);
    vec3 color = vColor * (0.82 + core * 1.5);
    gl_FragColor = vec4(color, (halo * 0.72 + core * 0.28) * uOpacity);
  }
`;

function cubicBezier(
  start: THREE.Vector3,
  controlA: THREE.Vector3,
  controlB: THREE.Vector3,
  end: THREE.Vector3,
  progress: number,
  target: THREE.Vector3,
): void {
  const inverse = 1 - progress;
  const inverseSquared = inverse * inverse;
  const progressSquared = progress * progress;
  target.set(
    inverseSquared * inverse * start.x
      + 3 * inverseSquared * progress * controlA.x
      + 3 * inverse * progressSquared * controlB.x
      + progressSquared * progress * end.x,
    inverseSquared * inverse * start.y
      + 3 * inverseSquared * progress * controlA.y
      + 3 * inverse * progressSquared * controlB.y
      + progressSquared * progress * end.y,
    inverseSquared * inverse * start.z
      + 3 * inverseSquared * progress * controlA.z
      + 3 * inverse * progressSquared * controlB.z
      + progressSquared * progress * end.z,
  );
}

function DataSignals({progressRef}: JourneyCanvasProps): React.JSX.Element {
  const pointsRef = useRef<THREE.Points>(null);
  const signalData = useMemo(createSignalData, []);
  const geometry = useMemo(() => {
    const nextGeometry = new THREE.BufferGeometry();
    nextGeometry.setAttribute('position', new THREE.BufferAttribute(signalData.positions, 3));
    nextGeometry.setAttribute('color', new THREE.BufferAttribute(signalData.colors, 3));
    nextGeometry.setAttribute('aSize', new THREE.BufferAttribute(signalData.sizes, 1));
    return nextGeometry;
  }, [signalData]);
  const material = useMemo(() => new THREE.ShaderMaterial({
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    fragmentShader: particleFragmentShader,
    transparent: true,
    uniforms: {
      uOpacity: {value: 1},
      uPixelRatio: {value: Math.min(window.devicePixelRatio, 1.5)},
      uPulse: {value: 0},
    },
    vertexShader: particleVertexShader,
  }), []);

  const fromPosition = useMemo(() => new THREE.Vector3(), []);
  const toPosition = useMemo(() => new THREE.Vector3(), []);
  const startPosition = useMemo(() => new THREE.Vector3(), []);
  const controlA = useMemo(() => new THREE.Vector3(), []);
  const controlB = useMemo(() => new THREE.Vector3(), []);
  const endPosition = useMemo(() => new THREE.Vector3(0, 0, -1.4), []);
  const fromColor = useMemo(() => new THREE.Color(), []);
  const toColor = useMemo(() => new THREE.Color(), []);
  const flowColor = useMemo(() => new THREE.Color('#75d6f4'), []);
  const cleanColor = useMemo(() => new THREE.Color('#a1efe1'), []);
  const modelColor = useMemo(() => new THREE.Color('#8ec9ee'), []);
  const outputColor = useMemo(() => new THREE.Color('#daf7ff'), []);
  const exceptionColor = useMemo(() => new THREE.Color('#ff956d'), []);
  // Mức tách ngoại lệ bám theo scroll (0 = chưa lọc, 1 = đã tách hẳn), cập nhật mỗi frame.
  const rejectionRef = useRef(0);

  useEffect(() => () => {
    geometry.dispose();
    material.dispose();
  }, [geometry, material]);

  const setStatePosition = (
    state: number,
    index: number,
    elapsed: number,
    target: THREE.Vector3,
  ) => {
    const offset = index * 3;
    const phase = signalData.phases[index];

    if (state === 0) {
      target.set(
        signalData.rawPositions[offset] + Math.sin(elapsed * 0.65 + phase * 10) * 0.025,
        signalData.rawPositions[offset + 1] + Math.cos(elapsed * 0.55 + phase * 8) * 0.025,
        signalData.rawPositions[offset + 2] + Math.sin(elapsed * 0.4 + phase * 6) * 0.035,
      );
      return;
    }

    if (state === 1) {
      const movingProgress = (phase + elapsed * 0.095) % 1;
      const source = SOURCE_CENTERS[signalData.sourceIndexes[index]];
      startPosition.set(
        signalData.rawPositions[offset],
        signalData.rawPositions[offset + 1],
        signalData.rawPositions[offset + 2],
      );
      controlA.set(source.x * 0.72, source.y * 0.8, 0.7);
      controlB.set(source.x * 0.18, source.y * 0.12, 0.15);
      cubicBezier(startPosition, controlA, controlB, endPosition, movingProgress, target);
      target.x += Math.sin(movingProgress * Math.PI * 5 + phase * 4) * 0.035;
      target.y += Math.cos(movingProgress * Math.PI * 4 + phase * 3) * 0.035;
      return;
    }

    if (state === 2) {
      const movingProgress = (phase + elapsed * 0.078) % 1;
      const lane = (index % 11) - 5;
      target.set(
        -4.25 + movingProgress * 8.5,
        lane * 0.135 + Math.sin(movingProgress * Math.PI * 8 + phase * 4) * 0.07,
        Math.cos(movingProgress * Math.PI * 5 + lane) * 0.32,
      );
      if (signalData.invalid[index]) {
        const lift = smoothstep(0.42, 0.86, movingProgress) * rejectionRef.current;
        target.y += lift * 2.8;
        target.x -= lift * 0.45;
      }
      return;
    }

    if (state === 3) {
      target.set(
        signalData.modelPositions[offset] + Math.sin(elapsed * 0.32 + phase * 9) * 0.09,
        signalData.modelPositions[offset + 1] + Math.cos(elapsed * 0.28 + phase * 7) * 0.09,
        signalData.modelPositions[offset + 2],
      );
      return;
    }

    target.set(
      signalData.outputPositions[offset],
      signalData.outputPositions[offset + 1],
      signalData.outputPositions[offset + 2],
    );
  };

  const setStateColor = (state: number, index: number, target: THREE.Color) => {
    const offset = index * 3;
    if (state === 0) {
      target.setRGB(
        signalData.baseColors[offset],
        signalData.baseColors[offset + 1],
        signalData.baseColors[offset + 2],
      );
      return;
    }
    if (state === 1) {
      target.copy(flowColor);
      return;
    }
    if (state === 2) {
      target.copy(signalData.invalid[index] ? exceptionColor : cleanColor);
      return;
    }
    target.copy(state === 3 ? modelColor : outputColor);
  };

  useFrame(({clock}) => {
    const progress = clamp01(progressRef.current);
    const elapsed = clock.getElapsedTime();
    const scaledProgress = stageProgress(progress);
    const fromState = Math.min(3, Math.floor(scaledProgress));
    const toState = fromState + 1;
    const mixAmount = scaledProgress - fromState;

    for (let index = 0; index < PARTICLE_COUNT; index += 1) {
      const offset = index * 3;
      setStatePosition(fromState, index, elapsed, fromPosition);
      setStatePosition(toState, index, elapsed, toPosition);
      setStateColor(fromState, index, fromColor);
      setStateColor(toState, index, toColor);

      signalData.positions[offset] = THREE.MathUtils.lerp(fromPosition.x, toPosition.x, mixAmount);
      signalData.positions[offset + 1] = THREE.MathUtils.lerp(fromPosition.y, toPosition.y, mixAmount);
      signalData.positions[offset + 2] = THREE.MathUtils.lerp(fromPosition.z, toPosition.z, mixAmount);
      signalData.colors[offset] = THREE.MathUtils.lerp(fromColor.r, toColor.r, mixAmount);
      signalData.colors[offset + 1] = THREE.MathUtils.lerp(fromColor.g, toColor.g, mixAmount);
      signalData.colors[offset + 2] = THREE.MathUtils.lerp(fromColor.b, toColor.b, mixAmount);
    }

    geometry.attributes.position.needsUpdate = true;
    geometry.attributes.color.needsUpdate = true;
    material.uniforms.uPulse.value = Math.sin(elapsed * 1.4) * 0.5 + 0.5;
    // Chương "Chất lượng" (0.37–0.57): quy tắc lọc dần theo scroll, nền mờ đi để đọc rõ Quality Gate.
    rejectionRef.current = smoothstep(0.42, 0.5, progress);
    const qualityFocus = peak(progress, 0.37, 0.44, 0.52, 0.60);
    // Chương 04 là sơ đồ dày chữ: hạt phải lùi gần hết để không thành nhiễu sau các thẻ.
    const erdFocus = peak(progress, 0.56, 0.62, 0.72, 0.80);
    material.uniforms.uOpacity.value = 0.86 - Math.max(erdFocus * 0.72, qualityFocus * 0.44)
      + smoothstep(0.82, 0.93, progress) * 0.14;

    if (pointsRef.current) {
      pointsRef.current.rotation.y = Math.sin(elapsed * 0.2) * 0.012;
    }
  });

  return <points ref={pointsRef} geometry={geometry} material={material} frustumCulled={false} />;
}

interface CardFrameProps {
  labelRef: React.RefCallback<HTMLDivElement>;
  position: [number, number, number];
  source: JourneySource;
}

function CardFrame({labelRef, position, source}: CardFrameProps) {
  return (
    <group position={position}>
      <Html center position={[0, 0, 0.09]} style={{pointerEvents: 'none'}} zIndexRange={[20, 0]}>
        <div
          className={styles.sourceNode}
          ref={labelRef}
          style={{'--source-accent': source.accent} as React.CSSProperties}
        >
          <header className={styles.sourceNodeHeader}>
            <span className={styles.sourceGlyph}>{source.glyph}</span>
            <span className={styles.sourceIdentity}>
              <strong>{source.name}</strong>
              <small>{source.domain}</small>
            </span>
            <span className={styles.sourceMode}>{source.mode}</span>
          </header>

          <div className={styles.sourceTable}>
            <div className={styles.sourceColumns}>
              {source.columns.map((column) => <span key={column}>{column}</span>)}
            </div>
            {source.records.map((record) => (
              <div className={styles.sourceDataRow} key={record.id}>
                <code>{record.id}</code>
                {record.values.map((value, index) => <span key={`${record.id}-${index}`}>{value}</span>)}
              </div>
            ))}
          </div>

          <footer className={styles.sourceNodeFooter}>
            <span><i /> Đang nhận dữ liệu</span>
            <time>{source.updatedAt}</time>
          </footer>
        </div>
      </Html>
    </group>
  );
}

function SourceWorld({progressRef}: JourneyCanvasProps): React.JSX.Element {
  const groupRef = useRef<THREE.Group>(null);
  const labelRefs = useRef<Array<HTMLDivElement | null>>([]);

  useFrame(({clock}) => {
    const group = groupRef.current;
    if (!group) return;
    // Thẻ nguồn phải tắt hẳn trước ngưỡng 0.37, nếu không sẽ chồng lên Quality Gate
    // đang hiện lên và cảnh bị đục.
    const visibility = 1 - smoothstep(0.315, 0.368, progressRef.current);
    group.visible = visibility > 0.01;
    group.scale.setScalar(0.92 + visibility * 0.08);
    group.position.z = -0.8 + visibility * 0.8;
    group.rotation.y = Math.sin(clock.getElapsedTime() * 0.22) * 0.025;
    labelRefs.current.forEach((label) => {
      if (!label) return;
      label.style.opacity = visibility.toFixed(3);
      label.style.transform = `scale(${(0.96 + visibility * 0.04).toFixed(3)})`;
      label.style.visibility = visibility > 0.02 ? 'visible' : 'hidden';
    });
  });

  return (
    <group ref={groupRef}>
      {SOURCE_CENTERS.map((center, index) => (
        <CardFrame
          key={journeySources[index].name}
          labelRef={(node) => {labelRefs.current[index] = node;}}
          position={[center.x, center.y, center.z]}
          source={journeySources[index]}
        />
      ))}
    </group>
  );
}

function CameraRig({progressRef}: JourneyCanvasProps): null {
  const targetPosition = useMemo(() => new THREE.Vector3(), []);
  const lookAt = useMemo(() => new THREE.Vector3(), []);

  useFrame(({camera, pointer}) => {
    const progress = clamp01(progressRef.current);
    const sourceZoom = smoothstep(0.06, 0.23, progress);
    const processingZoom = smoothstep(0.315, 0.425, progress);
    const modelPullback = smoothstep(0.515, 0.625, progress);
    const dashboardPullback = smoothstep(0.715, 0.825, progress);

    targetPosition.set(
      pointer.x * 0.12 + processingZoom * 0.18 - modelPullback * 0.18,
      pointer.y * 0.08 + Math.sin(progress * Math.PI * 2) * 0.08,
      10.4 - sourceZoom * 1.15 - processingZoom * 0.62 + modelPullback * 1.1 + dashboardPullback * 0.55,
    );
    camera.position.lerp(targetPosition, 0.085);
    lookAt.set(0, 0, -0.4 + processingZoom * 0.45);
    camera.lookAt(lookAt);
  });

  return null;
}

function StoryScene({progressRef}: JourneyCanvasProps): React.JSX.Element {
  return (
    <>
      <color attach="background" args={['#07131f']} />
      <fog attach="fog" args={['#07131f', 10, 18]} />
      <ambientLight intensity={0.25} />
      <pointLight color="#69c9ee" intensity={12} position={[0, 1.5, 4]} distance={15} />
      <pointLight color="#70dbc6" intensity={7} position={[-4, -2, 2]} distance={12} />

      <CameraRig progressRef={progressRef} />
      <SourceWorld progressRef={progressRef} />
      <DataSignals progressRef={progressRef} />

      <EffectComposer multisampling={0}>
        <Bloom intensity={0.72} luminanceSmoothing={0.36} luminanceThreshold={0.3} mipmapBlur />
        <Vignette darkness={0.44} eskil={false} offset={0.22} />
      </EffectComposer>
    </>
  );
}

export default function JourneyCanvas({progressRef}: JourneyCanvasProps): React.JSX.Element {
  const mountRef = useRef<HTMLDivElement>(null);
  const [isVisible, setIsVisible] = useState(true);

  useEffect(() => {
    const mount = mountRef.current;
    if (!mount) return;

    const observer = new IntersectionObserver(
      ([entry]) => setIsVisible(entry.isIntersecting),
      {rootMargin: '60% 0px', threshold: 0},
    );
    observer.observe(mount);
    return () => observer.disconnect();
  }, []);

  return (
    <div className={styles.journeyCanvas} ref={mountRef} aria-hidden="true">
      <Canvas
        camera={{far: 30, fov: 45, near: 0.1, position: [0, 0, 10.4]}}
        dpr={[1, 1.5]}
        frameloop={isVisible ? 'always' : 'never'}
        gl={{alpha: true, antialias: true, powerPreference: 'high-performance'}}
      >
        <StoryScene progressRef={progressRef} />
      </Canvas>
    </div>
  );
}
