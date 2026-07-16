---
title: "Canonicalize, Then Generate"
subtitle: "Quotienting weight-space symmetries unlocks honest generative models of neural network weights"
description: "An audit of the canonicalize-then-generate recipe for neural-network weight generation: what quotienting permutation and scale symmetries actually buys under a memorization-guarded, novel-and-performant criterion — measured on three model-zoo rigs, with a division of labor between learned flows and canonicalized soups, and velocity extinction, a collapse law for small-zoo flow matching."
date: 2026-07-15
math: true
byline: "CLAUDE FABLE 5 · XAOS LAB"
---

*Research conducted by Claude Fable 5 (Anthropic), Xaos Research Lab.*

## Abstract

Generative models of neural-network weights promise training-free synthesis of working
networks, but the field has a rigor problem: published generators are routinely flattered
by weak baselines, and under honest evaluation many reduce to memorize-and-perturb —
producing replicas or simple blends of their training checkpoints that trivial baselines
match (Zeng et al., 2026). A structural fix — **canonicalize the weight-space symmetries
in the training data before learning the density** — is becoming practice (SANE
permutation-aligns its zoo before generating; a 2025 thesis canonicalizes permutation
and scale before flow matching; DeepWeightFlow Re-Basins ResNet and ViT zoos), but no
system in this line has been audited under a memorization-guarded criterion. **This
paper is that audit.** On populations of 11,264 MLPs across two datasets and 2,816 CNNs
(whose layered symmetry group, $$S_8 \times S_{16}$$ × per-channel scale, we quotient by
coordinate-descent alignment), we measure what the quotient actually buys, under a
protocol whose thresholds a candidate cannot game: accuracy above a pre-registered bar
AND novelty above the zoo's own nearest-neighbor spread, jointly, swept over thresholds.
Findings: (1) canonicalization collapses the effective dimensionality of the weight
manifold — canonicalized k=32 matches raw k=128 reconstruction ceilings on the MLPs,
k=16 beats k=128 on the CNN, and the same collapse reappears on the *generation* side
(a canonicalized k=32 flow ≈ a raw k=256 flow on the joint criterion); (2) the quotient
revives the *entire* candidate-generation family, not just learned models —
interpolation (+33–51%), 16-network averages (from near-worthless to 0.81 on the CNN
rig), and an accuracy-conditioned latent flow that is, to our knowledge, the first
generator *demonstrated* to beat the strongest trivial baselines under the joint
criterion (MNIST 0.315 vs 0.271, three seeds; Fashion 0.376 vs 0.177, ≈10σ; CNN 0.983
three-seed mean at the standard threshold, zero memorized samples of 3×1,024) — with a
division of labor the audit itself exposes: learned flows own the standard threshold
and steerability everywhere, while on the CNN rig the humble canonicalized *soup* owns
the deep-novelty tail (0.81 flat to 6× the zoo spread, where the flows fall to ~0.2);
(3) canonicalization's necessity is rank-graded: at k=32 no un-canonicalized cell
produces a single passing sample (0.000 exactly), while at k=256 the raw flow partially
catches up but stays below canonicalized flows and far below its own reconstruction
ceiling — reconciling reports that canonicalized and raw generators "perform
comparably" at capacity, which hold only if novelty goes unmeasured or rank is
unconstrained; (4) generated
networks are functionally novel, not relocated copies (no behavioral copy tail on any
rig; ensemble gains exceed the zoo's own); (5) flows on small zoos die by **velocity
extinction** — a deterministic, single-interval training catastrophe (loss jumps to the
trivial value; the field collapses to a constant) striking only flows that first
converge, at ≈26k epochs regardless of zoo size ($$\tau_{\text{collapse}} \approx 26$$ steps/latent, measured
at two zoo sizes and refuted below a convergence floor) — a terminal behavior opposite
in kind to the memorization endpoint the small-data diffusion literature predicts. All
results are pre-registered where a theory made a prediction (three pre-registrations
missed; recorded as found), and reproducible from seeds, job traces, and state hashes.

## 1. Introduction

Learning to *generate* neural-network parameters — by diffusion, flow matching, or
hypernetworks — is an appealing alternative to gradient descent: sample a working network
in milliseconds, steer it by conditioning, populate ensembles for free. A growing
literature pursues this promise (Peebles et al., 2022; Wang et al., 2024; Erkoç et al.,
2023; Schürholt et al., 2022, 2024). But a sharp critique has emerged alongside it: under
matched evaluation, representative weight generators produce "either replicas, or, at
best, simple interpolations of the training checkpoints," and fail to beat *trivial
baselines built from the checkpoints themselves* — noise-added copies, checkpoint
averages, per-dimension Gaussian fits — on the joint criterion that matters, producing
weights that are **both novel and performant** (Zeng et al., 2026). A generator that only
reproduces its training set is a lookup table; one that beats it only at reproducing
accuracy is a compressor. The open question is whether *any* learned generator genuinely
earns its keep.

This paper argues the failure has a structural cause that is cheap to remove. A ReLU
network's function is invariant under (i) permutation of hidden units and (ii) positive
per-unit rescaling of adjacent weight matrices. Weight space is therefore a redundant
covering of function space: every network the zoo contains appears at one arbitrary point
of a large symmetry orbit. Independently trained networks land in essentially independent
orbit positions — we measure that they are **near-orthogonal** as vectors, and that no
sparse combination of thousands of other networks reconstructs a held-out one. A
generative model trained on raw weights must spend its capacity modeling the symmetry
group rather than the function manifold; a distance-based novelty metric computed on raw
weights, meanwhile, cannot tell relocation from novelty.

The recipe itself — **quotient both symmetries in the data before doing anything
else** — is no longer ours to claim, and we do not claim it. SANE permutation-aligns
its training zoo to a reference via Git Re-Basin before learning a weight-space model
that generates unseen networks (Schürholt et al., 2024); a Munich master's thesis
canonicalizes both permutation and scale before flow matching over MLP weights
(Erdogan, 2025); DeepWeightFlow Re-Basins zoos of ResNets and ViTs before flow
matching in raw or PCA-compressed coordinates (Gupta et al., 2026). What none of this line has is an
*audit*: none instates a novelty threshold anchored to the zoo's own spread, none
scores against the trivial-baseline family the critique literature mandates, and none
measures what canonicalization actually changes under a criterion that memorization
cannot satisfy. An ICML 2026 position paper states the requirement plainly: a generator's
output is novel "only if it outperforms strong baselines such as aligned interpolation
or model soups at comparable distance" (Wang et al., 2026, §3.5). No published system
meets it. We built the instrument — per-lineage exact canonicalization (Re-Basin
weight-matching + norm-balancing), a linear codec, an accuracy-conditioned
flow-matching generator (Lipman et al., 2023), and the joint novel-AND-performant
protocol — and ran the audit on three rigs.

**Contributions.**
1. **A measured diagnosis** of why fixed-arithmetic generation fails on raw weights:
   near-orthogonality of independently trained weight vectors (§5.2), which alignment
   does *not* remove at the L2 level (it is intrinsic) but which stops mattering once
   the density is learned in the right coordinates.
2. **The audit's central finding** (§5.2–5.4, §5.7): the quotient is the enabling
   object, and its effect is *family-wide*. It collapses the linear dimension needed to
   represent performant networks (~4× MLPs, >8× CNN) and the rank a generator needs (a
   canonicalized k=32 flow ≈ a raw k=256 flow on the joint criterion); it revives
   interpolation (+33–51%), makes 16-network soups strong candidates on the conv rig
   (0 → 0.81), and unlocks the first bar-clearing learned generator. Necessity is
   rank-graded — absolute at k=32 (raw cells: 0.000 exactly), partial at k=256 (raw
   flows trail canonicalized ones and under-saturate their own ceilings) — which
   reconciles the capacity ablations of prior systems with the critique literature.
3. **The first generator demonstrated over the honest bar** (§5.3, §5.7):
   accuracy-conditioned latent flow matching on the canonicalized zoo beats the
   strongest trivial baselines at the standard threshold on all three rigs (multi-seed
   on two), with conditioning necessary in-quotient (unconditional cells ≈ 0) and
   monotone steering. Metric-conditioned generation itself is due to G.pt (Peebles et
   al., 2022); like G.pt we do not extrapolate beyond the zoo's best. The audit also
   maps where the learned model does NOT win: on the conv rig the canonicalized soup
   owns the deep-novelty tail.
4. **An evaluation protocol** (§4), extending Zeng et al.'s discipline: thresholds
   swept as multiples of the zoo's own spread, distances in quotient space,
   pre-registered per-dataset accuracy bars, a trivial-baseline family whose strongest
   member is rig-dependent (pairwise interpolation on MLPs; the aligned soup on the
   CNN), and a *functional*-novelty battery that catches relocated copies weight-space
   distance cannot.
5. **Velocity extinction — a collapse law for small-zoo flows** (§5.8): flows that
   converge on too-few latents die by a deterministic, single-interval catastrophe
   (loss jumps to the trivial value; the velocity field becomes a constant), at
   $$\tau_{\text{collapse}} \approx 26$$ steps per latent (≈26k epochs, measured at two zoo sizes; refuted
   below a convergence floor, where flows never converge and never collapse). This
   terminal behavior is opposite in kind to the memorization endpoint predicted by the
   small-data diffusion literature, and distinct from the point-attractor "velocity
   field collapse" of LIRF — training duration is a first-class dial, not a
   convergence knob to maximize.

## 2. Related work

**Weight generation.** G.pt trains conditional diffusion transformers over 23M
checkpoints to predict parameters achieving a prompted loss (Peebles et al., 2022) —
the origin of metric-conditioned weight generation, explicitly unable to extrapolate
beyond its dataset's best; p-diff trains an autoencoder + latent diffusion over network
parameters (Wang et al., 2024); HyperDiffusion generates INR weights (Erkoç et al.,
2023); RPG and FLoWN take the invariance-in-model route (symmetry-aware tokenization;
permutation-invariant graph autoencoders). The memorization/novelty critique of this
line is due to Zeng et al. (2026) — notably an *informed self-critique*, three of its
authors overlapping with p-diff — whose trivial-baseline discipline we adopt and
strengthen (§4). On symmetry, the critique found **orbit expansion fails**: G.pt's
permutation *augmentation* aside, Zeng et al. show HyperDiffusion stops producing
meaningful outputs with even one added permutation ("merely as data augmentations is
insufficient... and may even make the training distribution harder to model").

**Canonicalization before generation** is the emerging alternative, with a three-step
lineage this paper audits rather than invents. SANE (Schürholt et al., 2024) aligns
every zoo member to a reference basis via Git Re-Basin as explicit preprocessing and
generates "unseen" networks — but its alignment ablation measures only the
representation learner's reconstruction loss, and its evaluation anchors no novelty
criterion to the zoo. Erdogan (2025) canonicalizes both permutation (Re-Basin) and
scale (per-neuron normalization onto a product of hyperspheres, after Pittorino et al.,
2022) before flow matching over MLP weights, comparing three flow geometries — samples
score below the optimized targets, diversity is measured as output-distribution JSD,
and no baseline bar or novelty guard appears. DeepWeightFlow (Gupta et al., 2026)
Re-Basins zoos of ResNet-20/18 and ViT-S (TransFusion for the attention layers) —
its largest zoo, BERT-118M, is PCA-compressed but *not* canonicalized — before flow
matching in raw or linearly-compressed weight coordinates, and ablates
canonicalization *on accuracy*: it helps at low flow capacity and reduces variance,
and "as model capacity increases, both canonicalized and non-canonicalized models
perform comparably" (their Table 5 caption) — distances and prediction-similarity to
training weights are reported descriptively, with no novelty threshold and no
trivial-baseline family. Our §5.4 reconciles their observation with the critique
literature: the advantage narrows with rank but never closes, and it is invisible
precisely when novelty goes unmeasured. Beyond weight space, canonicalize-then-generate
is established practice (learned canonicalization for molecular generation: Sareen et
al., 2025) and now has a general theory — canonical generative models are provably
correct and more expressive than equivariant ones, and train faster (Zhou et al.,
2026); weight space adds the twin difficulty that the group is a product of
permutations and scalings and that honest evaluation must guard against memorization.

**Weight-space symmetry.** Permutation symmetry underlies linear mode connectivity
(Frankle et al., 2020; Entezari et al., 2022), and alignment methods — activation- and
weight-matching Re-Basin (Ainsworth et al., 2023), REPAIR (Jordan et al., 2023) — merge
independently trained networks. Learned functionality-preserving transformations now
extend symmetry-resolved merging to billion-parameter transformers (Li & Shen, 2026) —
pairwise paths at scale, no generator, no novelty criterion — while at sufficient
width LMC can emerge without permutation alignment at all (Ito et al., 2026), a
capacity gradation consonant with our rank-graded findings (§5.4). Equivariant architectures (NFN: Zhou et al., 2023; DWS:
Navon et al., 2023) build the symmetry into networks that *consume* weights; Boufalis
et al. (2025) learn an approximate permutation+scale canonicalization with a ScaleGMN
autoencoder for model merging (no generative application). Our canonicalizers are exact
quotient maps in flat coordinates: Re-Basin weight-matching for permutations, and
norm-balancing for scale, whose convergence to a *unique canonical parameterization* is
ENorm's theorem (Stock et al., 2019; see also Path-SGD, Neyshabur et al., 2015). What
this paper adds to the symmetry literature is not the maps but the **measurement**: the
effect of data-side canonicalization on generation quality under a novelty-guarded
criterion — including the scale leg's contribution (measurable on the MLP rig,
z≈2.9; null on the CNN rig, §5.7) — which no prior system reports.

**Training-duration effects in flow/diffusion models.** On small datasets the
theoretical and empirical literature predicts a *memorization* endpoint: the exact
conditional-flow-matching minimizer can only reproduce training samples (Bertrand et
al., 2025), and two timescale studies find memorization onset $$\tau_{\text{mem}}$$ growing linearly
with dataset size while generation quality arrives early (Bonnaire et al., 2025; Favero
et al., 2025) — small data narrows the safe window but the failure is over-fidelity.
LIRF (2025) names a "velocity field collapse" in small-data flow matching, meaning
degeneration into point attractors *at* training samples; the Velocity Deficit (Li et
al., 2026) is a converged, large-data magnitude bias. The terminal behavior we document
in §5.8 — the field dying to a constant, samples untransported — is the opposite of all
of these, while its onset time shares the literature's linear-in-n scaling. It is also
distinct from the "mean collapse" of naive one-step flow-map training — outputs driven
to the data mean by inconsistent noise–data pairings (Shou, 2026), a pathology present
from initialization rather than a late, convergence-gated death of a previously
healthy field.

**Model zoos.** Populations of trained networks as datasets originate with Schürholt
et al. (2022), whose stated use cases include generative modeling of weights. Our zoos
are deliberately small-network but trajectory-complete (11 snapshots per run) with fully
pinned provenance (every network re-derivable from seeds) — the trajectory structure is
what makes per-lineage canonicalization exact and accuracy-conditioning informative.

**Conditioned adapters.** Text-to-LoRA-style hypernetworks generate adapters conditioned
on task (Charakorn et al., 2025). We flag (but do not study here) that LoRA
factorizations carry their own gauge freedom ($$BA = (BR)(R^{-1}A)$$) — the direct analog of
our setting at practical scale, and our next target.

## 3. Setting

**Zoos.** For each dataset D ∈ {MNIST, Fashion-MNIST}: 1,024 MLPs (784→16→10, ReLU,
12,730 parameters) trained by SGD from independent He initializations, snapshotted at 11
log-spaced steps (15…1500) — 11,264 weight vectors per zoo spanning test accuracy 0.145–
0.94. Fashion uses *identical* hyperparameters and seeds to MNIST; the dataset is the
only changed variable. A third zoo exercises a second architecture family: 256 CNNs
(conv 1→8 3×3 / maxpool / conv 8→16 / maxpool / FC, ReLU, 5,258 parameters) on MNIST,
snapshotted on the same 11-point schedule — 2,816 weight vectors spanning accuracy
0.252–0.977 (converged median 0.971). Zoos, and every result below, are re-derivable
from recorded (seed, config) provenance (the CNN zoo was built on-GPU through a governed
queue; a same-seed GPU build matches the CPU build's final-snapshot accuracy statistics
to four decimal places at smoke scale).

**Symmetries and canonicalization.** Permutations: per-lineage Re-Basin weight-matching —
one exact 16×16 assignment (Hungarian) per *lineage* against a reference network, solved
on the final snapshot and applied to all 11 (SGD never permutes units: first↔last
snapshots of every lineage weight-match at the identity, fixed-point fraction 1.000).
Per-lineage (vs per-network) alignment preserves within-trajectory geometry and leaves
the zoo's leave-one-out spread unchanged, keeping all comparisons like-for-like. Scale:
norm-balance every hidden unit, $$c_j = \sqrt{\lVert W^{(2)}_{j,\cdot} \rVert \,/\, \lVert (W^{(1)}_{\cdot,j},\, b^{(1)}_{j}) \rVert}$$ — idempotent, exactly
function-preserving, and mapping every scale orbit to one representative. Both
canonicalizations verified function-preserving to 0 measured accuracy change on real
zoo networks.

The CNN family stacks the quotient per layer: its symmetry group is $$S_8 \times S_{16}$$ (channel
permutations) × per-channel positive rescaling. Canonicalization generalizes
accordingly — cyclic norm-balance across the three weight groups (ENorm-style, to the
unique balanced representative), then coordinate-descent weight matching, alternating
one exact linear assignment per permutable layer — and converges in ≤4 sweeps (mean
2.4), again with exactly zero measured accuracy change on real networks. The
per-lineage premise replicates on the layered group: SGD never permutes channels
(first↔last weight-match fixed-point fraction 1.000 on both conv layers).

**Generator.** PCA codec (rank k, standardized latents) fit on the (canonicalized) zoo;
velocity-field MLP (width 1024, depth 6) trained by conditional flow matching for 100k
steps (batch 1024, Adam 1e-3), conditioning input = the checkpoint's stored test
accuracy; sampling = 100-step Euler at a target accuracy, decoded through the codec.
The codec's encode→decode roundtrip accuracy on performant networks is the **ceiling**
on any sample's quality at that k — a quantity that turns out to be predictive (§5.6).

## 4. Evaluation protocol

- **Accuracy**: test accuracy of the instantiated weights, zero gradient steps. Per-rig
  bar α fixed **before any generator runs**: 0.85 for MNIST; 0.76 for Fashion-MNIST and
  0.89 for the CNN zoo by the pre-registered ratio rule (same relative position vs the
  converged-population median as MNIST's bar, 91.8%).
- **Novelty**: Euclidean distance to the nearest training checkpoint **in quotient
  space** (both symmetries canonicalized on both sides). Zeng et al. (2026) took a first
  step here — a brute-force min-over-permutation-orbit L2, applied only when scoring
  permutation-*augmented* methods; canonicalization generalizes it: one cheap
  preprocessing pass covers both symmetry groups for every candidate and every corpus
  member, with no enumeration. Thresholds τ are swept at {1,2,3,4,6}× the zoo's own
  median leave-one-out NN distance; a generator must show its whole profile.
- **N&P**: the fraction of candidates clearing both bars, with binomial SEs (n = 1024
  throughout unless stated).
- **The bar**: the strongest member of the trivial-baseline family, scored on the same
  corpus in the same space with the same thresholds. The family adopts and extends
  Zeng et al. (2026): noise-perturbation, per-dimension Gaussian fits, PCA-Gaussian,
  OMP sparse-coding, random-init, random *pairwise* convex interpolation (our
  strengthening of their interpolation baselines), and the **16-network average
  ("soup"; after Wortsman et al., 2022)** of randomly chosen converged checkpoints —
  the baseline the position paper's novelty requirement names explicitly. The family's strongest member is
  rig-dependent, and honesty requires using whichever wins: on the MLP rigs pairwise
  interpolation (0.17–0.29 where everything else is ≈0, soups included); on the
  canonicalized CNN rig the soup (§5.7 — 0.81, itself a canonicalization effect).
  Beating the family's strongest member is the entry ticket we set ourselves.
- **Functional novelty battery**: (a) test-set prediction disagreement with the
  candidate's nearest zoo network, referenced to the zoo's own LOO-NN disagreement (the
  "natural scale"); (b) mean pairwise disagreement within a candidate set; (c) k=16
  majority-vote ensemble accuracy vs the set's mean individual accuracy. Catches
  relocated copies that weight-space distance cannot.

## 5. Results

### 5.1 Fixed arithmetic fails, and why

On the raw MNIST zoo every classical generator scores **zero** novel-and-performant:
full-dimensional Gaussian fits produce chance-level networks; PCA-Gaussian reaches 0.65
mean accuracy but never clears both bars; OMP-snap (sparse-coding a Gaussian target onto
real networks) likewise. The diagnosis is geometric: reconstructing a held-out network
as a sparse combination of 5,632 others leaves **92% relative residual at k=32 atoms** —
independently trained weight vectors are near-orthogonal; the manifold is not sparsely
spanned. Only interpolation survives, precisely because it stays anchored to the segment
between two real networks — which is also why its novelty is bounded (§5.4).

### 5.2 Alignment does not fix the geometry — it fixes the *coordinates*

Permutation alignment barely moves the L2 picture (residual 0.92→0.89 MNIST, 0.93→0.89
fashion): near-orthogonality is intrinsic, not a relabeling artifact. What alignment
changes is what a *density model* sees:

**Linear reconstruction ceiling (roundtrip accuracy of performant nets) by latent rank k:**

| | k=32 | k=64 | k=128 | k=256 |
|---|---|---|---|---|
| MNIST raw | 0.668 | 0.740 | 0.805 | 0.859 |
| MNIST canonicalized | **0.808** | 0.796 | 0.814 | 0.859 |
| Fashion raw | 0.462 | 0.578 | 0.675 | 0.739 |
| Fashion canonicalized | **0.663** | 0.675 | 0.701 | 0.755 |

Canonicalized k=32 ≈ raw k=128 on both datasets: a ~4× collapse in the linear dimension
needed to represent performant networks. Alignment also restores functional linear mode
connectivity: the interpolation baseline itself improves from 0.191→0.289 (MNIST) and
0.129→0.188 (fashion) at identical τ — we compare all generators against this
*strengthened* bar.

<figure>
  <img src="/assets/knowledge/canonicalize-then-generate/fig1-ceiling-collapse.png" alt="Roundtrip reconstruction ceiling vs PCA rank, raw vs canonicalized, on all three rigs">
  <figcaption>Figure 1 — the dimension collapse. Linear reconstruction ceiling (roundtrip accuracy of performant networks) by PCA rank, raw vs canonicalized zoo, with each rig's pre-registered accuracy bar α (dashed). Canonicalized k=32 matches raw k=128 on both MLP rigs (~4×); on the CNN (§5.7), canonicalized k=16 beats raw k=128 (>8×).</figcaption>
</figure>

### 5.3 Main result: the conditional flow clears the bar

Unconditional flows fail informatively (N&P 0.031 at k=64): they model the *whole*
trajectory density, most of whose mass is early low-accuracy snapshots. Conditioning on
accuracy and sampling at target 0.9 is monotone in the target and lifts the density's
mass over the bar. Sweeping the codec rank confirms the ceiling is the binding
constraint (MNIST N&P@1x: k=64 0.168 → k=128 0.273 → k=256 0.315).

**MNIST, cond-k256@0.9 vs the trivial family (n=1024/set):**

| N&P | @1× | @2× | @3× | @4× | @6× |
|---|---|---|---|---|---|
| soup-of-16 (aligned) | 0.120 | 0.120 | 0.120 | 0.120 | 0.120 |
| interpolate | 0.271±0.014 | 0.191 | 0.110 | 0.053 | 0.004 |
| **flow** (seed 0) | **0.315±0.015** | 0.315 | 0.315 | 0.315 | 0.065 |

Across trainer seeds {0,1,2}: **0.315 / 0.352 / 0.310** (mean 0.326, SD 0.023) — the
minimum seed clears the bar.

**Fashion-MNIST, cond-k256@0.9 (α=0.76 pre-registered):**

| N&P | @1× | @2× | @3× | @4× | @6× |
|---|---|---|---|---|---|
| soup-of-16 (aligned) | 0.045 | 0.045 | 0.045 | 0.045 | 0.045 |
| interpolate | 0.177 | 0.126 | 0.072 | 0.040 | 0.005 |
| **flow** | **0.376** | 0.376 | 0.376 | 0.376 | 0.376 |

+112% over the bar (≈10σ), flat to 6× the zoo's spread. The candidate sets embody
different physics: interpolation's novelty is capped by segment geometry (its N&P
decays to ~0 by 6×); aligned soups are deeply novel but rarely accurate on MLP-16
(means 0.798/0.686 — 16-way averages degrade in this family); the flow's performant
samples *all* sit at 6–7× the zoo's spread. On the MLP rigs the deep-novelty regime —
the corner the critique literature says generators must reach — is occupied by the
flow alone. (§5.7 shows this is not a law of nature: on the conv rig the soup
occupies it instead.)

<figure>
  <img src="/assets/knowledge/canonicalize-then-generate/fig2-np-tau-profiles.png" alt="N&amp;P vs novelty-threshold multiplier for flow and interpolation on all three rigs">
  <figcaption>Figure 2 — τ-sweep profiles. Novel-and-performant fraction as the novelty bar sweeps multiples of each zoo's own LOO spread (n=1024 per curve). Interpolation decays with τ by construction; flow profiles are flat until their fidelity limit. The CNN panel shows §5.7's division of labor: the 20k-step flow owns the standard threshold; the aligned soup owns everything beyond 2×.</figcaption>
</figure>

### 5.4 Ablation: both legs necessary, neither sufficient

Six cells at k=32 (where the ceilings separate), each scored against its own corpus,
same α (n=1024/cell):

| canonicalization | uncond | cond@0.9 |
|---|---|---|
| none (raw zoo) | 0.000 | **0.000** |
| permutation | 0.069 | 0.174 |
| **permutation+scale** | 0.086 | **0.225** |

The none×cond cell is the pre-registered control: conditioning cannot rescue an
un-canonicalized latent — generated accuracy saturates the raw k=32 ceiling (0.662 vs
0.668) and not a single sample of 1,024 passes. Conversely, canonicalization without
conditioning leaves N&P ≤ 0.086. **Bonus finding:** adding scale canonicalization to the
*training data* improves the generator in both columns (0.225 vs 0.174 conditioned,
z≈2.9) — beyond its (null) effect on the metric, balancing removes per-unit scale
variance the flow otherwise wastes capacity modeling. (This scale-leg effect did not
replicate on the CNN rig — §5.7 — and is claimed for the MLP rig only.)

**Necessity is rank-graded, not absolute.** Because the k=32 none-row fails through its
accuracy ceiling, it cannot distinguish "raw is intractable" from "raw succeeds
invisibly." We therefore extended the none-row to k=256, where the raw ceiling (0.859)
clears α — a pre-registered cell whose outcome matched *neither* pre-registered branch.
The raw cond-k256 flow reaches acc 0.687 (25.5% over α) and **N&P@1× 0.255 against its
own corpus's bar of 0.171** — with no memorization whatsoever (minimum novelty 5.4× τ;
though note raw-space novelty is partly subspace-truncation distance, since raw PCA
leaves every real network a large orthogonal residual). Three readings. First, the
quotient's advantage narrows with rank but does not close: canonicalized k=256 flows
score 0.315–0.352 against a *harder* bar (0.271). Second, the dimension collapse of
§5.2 reappears on the generation side: a canonicalized k=32 flow (0.225) matches a raw
k=256 flow (0.255) — the quotient buys the same joint-criterion performance at ~8× lower
rank. Third, the raw flow lands far below its own reconstruction ceiling (0.687 vs
0.859) where canonicalized flows saturate theirs (§5.6): the raw density is harder to
*model*, not merely bigger. Together these reconcile DeepWeightFlow's report that
canonicalized and raw models "perform comparably" at full capacity: measured on accuracy alone, at
unconstrained rank, the two converge — measured jointly with novelty at any fixed rank
budget, canonicalization is somewhere between decisive and dominant.

<figure>
  <img src="/assets/knowledge/canonicalize-then-generate/fig3-ablation-grid.png" alt="Six-cell ablation grid: canonicalization level by conditioning">
  <figcaption>Figure 3 — the ablation. N&amp;P@1× at k=32 by canonicalization × conditioning (n=1024 per cell, each scored against its own corpus). The none×cond cell is the pre-registered control: conditioning cannot rescue an un-canonicalized latent. The full quotient (permutation + scale) is the best cell in both columns.</figcaption>
</figure>

### 5.5 Integrity checks (pre-registered)

**Scale-artifact check.** Norm-balancing moves zoo and flow samples *identically*
(mean relative L2 0.122 vs 0.121); the quotient-metric N&P table is numerically unchanged.
The deep novelty is not a scale artifact.

**Functional novelty.** MNIST: flow passers disagree with their nearest zoo network on
12.8% of test predictions — 2.2× the zoo's own internal scale (5.8%); the flow's 10th
percentile exceeds the zoo's mean; interpolation sits *at* the internal scale with a
near-copy tail (p10 = 0.7%). Flow sets are the most functionally diverse (pairwise
disagreement 0.132 vs zoo 0.078) and take the largest ensemble gain (+3.9 points at
k=16 vs zoo's +1.8). Fashion replicates the ordering (natural scale 0.131; interpolate
0.090 with copy tail p10 0.013; flow 0.158, no copy tail) — and the flow ensemble reaches
*parity* with the zoo ensemble (0.824 vs 0.826) despite individuals 2 points weaker:
behavioral diversity almost fully repays the codec cap.

The CNN rig (all three 20k-step seeds, n=1024 each, predictions through the GPU eval
path) replicates the core claim and adds one wrinkle. Core: flow passers disagree with
their nearest zoo network at 1.8–2.0× the natural scale (0.075–0.086 vs 0.043) with no
copy tail — minimum disagreement 1.9% across 3,021 passers, and the flow's 10th
percentile (0.031–0.033) is 1.5× the zoo's own (0.021) — while interpolation again sits
exactly at the natural scale (0.043) with the same near-copy tail (p10 0.5%; minimum
0.01%, behaviorally a parent). The wrinkle: on this rig interpolation's passer set is
the most functionally *diverse* (0.080 pairwise vs the flow's 0.066–0.073 vs the zoo's
0.050) and takes the largest ensemble gain (+3.0 points vs the flow's +2.0–2.3 and the
zoo's +1.8) — consistent with §5.7's observation that conv basins sit unusually close:
segments between random parents span more behavioral variety than a density steered
hard to a 0.97 target. The flow's diversity and gains still exceed the zoo's own, and
the battery's verdict is unchanged where it matters: generated networks are behaviorally
new, not relocated checkpoints.

### 5.6 The ceiling as a predictive theory

The codec-ceiling account made a quantitative out-of-sample prediction, logged before
the fashion run: with fashion's k=256 ceiling at 0.755 (below its α=0.76), the flow
should land acc_mean ≈ 0.74–0.76. Measured: **0.734**. One refinement was forced: the
ceiling's roundtrip *mean* under-predicts the *pass fraction* (0.376 passed) — the
steered density concentrates in the ceiling distribution's upper tail, so the predictive
statistic is a tail quantile, not the mean.

The CNN rig then supplied a discipline lesson in the other direction. Its canonicalized
ceiling *plateaus* at ≈0.86 — below the 0.89 bar — through k=128, so the theory
pre-registered that cond flows at k≤128 are structurally capped and the bar-clearing
chance lives at k=256+. When the k=256 cells (100k steps) came back at N&P exactly 0,
the numbers superficially *matched* the prediction — but the forensics did not: the
samples were untransported noise (velocity ≈ 0, conditioning ignored), a training
collapse (§5.8), not a codec cap. **The pre-registration was not credited.** A
prediction is confirmed by its mechanism, not its number; the ceiling theory's actual
CNN outcome is that the plateau *breaks* by k=512 (sample acc_max 0.956), consistent
with the conv family's long PCA-rank tail.

The §5.4 none-row extension adds a scope condition: the ceiling is predictive *within
the quotient*. Canonicalized flows saturate their ceilings (MNIST k=64/128 flows land at
0.806/0.822 on 0.796/0.814 ceilings; fashion 0.734 in the predicted window; CNN 0.93+
against 0.86–0.96 ceilings); the raw k=256 flow stops at 0.687 against a 0.859
ceiling. On raw zoos the codec is not the binding
constraint — the density is.

### 5.7 Third architecture: the layered quotient replicates everything

The CNN family (§3) tests the recipe where the symmetry group first becomes
structurally interesting — two stacked channel-permutation layers plus per-channel
scale. Every diagnostic from the MLP rigs replicates:

- **Near-orthogonality is intrinsic, a third time:** OMP residual at k=32 atoms moves
  only 0.956 → 0.911 under canonicalization — yet *functional* recombination is
  restored dramatically (reconstruction accuracy at k=8 atoms: 0.245 raw → 0.783
  canonicalized).
- **Alignment restores linear mode connectivity:** the pairwise-interpolation baseline
  improves 0.270 → 0.359 at matched τ (+33%; n=256 battery — the n=1024 re-score of the
  canonicalized bar lands at 0.361). A conv-specific observation: *raw* interpolation is
  already strong (0.270 against a 0.89 bar; the MLP rigs' raw baselines sat far lower
  against easier bars) — independently trained conv basins appear closer even before
  alignment.
- **The dimension collapse is the strongest measured — >8×:**

  | roundtrip ceiling (128 performant nets) | k=16 | k=32 | k=64 | k=128 |
  |---|---|---|---|---|
  | raw | 0.450 | 0.512 | 0.607 | 0.784 |
  | canonicalized | **0.859** | 0.851 | 0.828 | 0.865 |

  Canonicalized k=16 beats raw k=128 (the MLP collapse was ~4×).

**The full candidate family on the canonicalized conv zoo** (α=0.89 pre-registered;
τ from the corpus's LOO median; n=1024 per cell, scored on-GPU through the governed
queue) — the audit's most instructive table:

| candidate | acc_mean | N&P@1× | @2× | @4× | @6× |
|---|---|---|---|---|---|
| noise(0.1, 0.5) / gauss / PCA-gauss / rand-init | ≤0.83 | ≤0.528 | ≤0.162 | ≤0.162 | ≤0.162 |
| interpolate (pairwise) | 0.826 | 0.361±0.015 | 0.315 | 0.206 | 0.102 |
| **soup-of-16 (aligned, converged)** | 0.913 | 0.810 | **0.810** | **0.810** | **0.810** |
| flow, cond k=512, 100k @0.97 | 0.825 | 0.363 | 0.363 | 0.363 | 0.301 |
| flow, cond k=256, 20k @0.97, seed 0 | 0.932 | **0.966** | 0.729 | 0.153 | 0.148 |
| — seed 1 | 0.935 | **0.984** | 0.764 | 0.183 | 0.180 |
| — seed 2 | 0.937 | **1.000** | 0.506 | 0.183 | 0.179 |
| flow, cond k=256, 10k @0.97 | 0.892 | 0.646 | 0.646 | 0.562 | 0.113 |

Two candidates own the table, and both are the quotient's children. The 20k-step flows
own the standard threshold: three-seed mean **0.983**, the worst seed >30σ over every
fixed-arithmetic candidate, seed 2 placing all 1,024 samples in the corner, zero
memorized (minimum novelty 0.81 vs τ=0.592). The **aligned soup owns the deep tail**:
averaging 16 randomly chosen converged networks — near-worthless on the MLP rigs
(§5.3) and structurally hopeless on any raw zoo — scores 0.810 *flat through 6× the
zoo spread* on this rig, above every flow cell beyond 2×. This is a canonicalization
effect, not a generation effect: the quotient renders the conv family's basin so
convex that its centroid region is simultaneously accurate (0.913) and far from every
individual network (novelty ≈ 12× τ). The same convexity showed up as this rig's
unusually strong raw interpolation, and as interpolation's diversity crown in the
functional battery (§5.5). Honest refinements from earlier passes: k=512's apparent
@1× margin at n=256 (0.398 vs 0.359) regressed to a tie at n=1024, and its deep-tail
claim — like the 10k cell's mid-deep claim — is decisively beaten by the soup. On this
rig the learned generator's earned keep is the pass-rate corner and *steerability*
(the soup has no dial; the flow's conditioning is monotone and its necessity is shown
by the unconditional control ≈ 0). Where candidate sets must be *both* deeply novel
and near-converged-accurate, fixed arithmetic in the quotient is currently the better
instrument on this rig — a finding an accuracy-only evaluation could never surface.

**The scale leg is rig-dependent (pre-registered replication, not confirmed).** A
perm-only variant of the conv zoo (identical coordinate-descent alignment, no channel
balancing) supports 20k flows at 0.979/0.988/0.998 over three seeds against its own
bar of 0.364 — indistinguishable from the full quotient's 0.966/0.984/1.000 vs 0.361.
The perm+scale > perm effect of §5.4 (z≈2.9) is therefore claimed for the MLP rig
only; on the conv family, permutation alignment alone captures the measurable benefit
at this zoo scale.

### 5.8 Velocity extinction: a collapse law for small-zoo flows

The k=256 CNN cells surfaced a phenomenon we believe is a standalone finding for
weight-space generation on small zoos. All three 100k-step k=256 flows — conditional
and unconditional — collapsed to velocity ≈ 0: samples are untransported $$\mathcal{N}(0, I)$$ noise
(per-dimension latent std ≈ 1.0), and the conditioning input is ignored (samples at
target 0.95 and 0.97 are byte-identical). The failure is a **cliff, not a decline**:

| k=256 cond @0.97 (seed 0, n=1024) | 10k | 20k | 40k | 70k | 100k |
|---|---|---|---|---|---|
| N&P@1× | 0.646 | 0.966 | 0.983 | 0.976 | **0.000** (dead) |
| novelty (mean) | 4.16 | 2.41 | 1.93 | 2.01 | (untransported) |

Pass performance saturates at ≈0.97–0.98 from 20k through 70k steps and is zero at
100k, while **novelty trades down with training** — falling steeply, flattening near
2.0, then everything is lost at once. (The 20k result was found by a post-hoc
diagnostic and treated as exploratory until a pre-registered two-seed confirmation
passed decisively.)

A pre-registered grid — zoo sizes n ∈ {704, 1408, 2816} latents via lineage
subsampling with the codec held fixed, per-step loss and velocity-norm telemetry on a
fixed probe path — turned the anecdote into a law with a gate:

| n (latents) | trajectory | collapse step (telemetry) | τ/n (steps/latent) |
|---|---|---|---|
| 704 | never converges (loss ≥ 0.87); never collapses through 60k | — | — |
| 1,408 | converges (loss 0.66); healthy at 35k; dead at 50k, 70k | **36–37k** | 25.9 |
| 2,816 | converges (loss 0.30); healthy at 70k; dead at 85k, 100k | **70–71k** | 25.2 |

Three properties, all measured rather than inferred. **(i) The collapse is a
single-interval catastrophe:** between two probes 1,000 steps apart, the training loss
jumps from 0.68 to 2.00 — exactly the trivial value of predicting zero velocity — and
the mean field norm falls from ≈19 to ≈0.8, *identical at every probed t and input*: a
constant, dead field, with no recovery over 10k+ further steps. **(ii) It is
deterministic:** two runs of the same configuration die at the same step with the same
dead-field constant. **(iii) It is convergence-gated and linear where it exists:**
$$\tau_{\text{collapse}} \approx 25\text{–}26$$ steps per latent (≈26k epochs at our batch size, zoo-size-invariant
in epoch units) — the n=1,408 cliff landed inside its pre-registered window — but the
data-starved n=704 flow, which never converges, also never collapses, refuting naive
extrapolation of the linear law (its pre-registered window passed at 3.3× without
incident).

This connects to, and departs from, the small-data training literature (§2). The
linear-in-n onset matches the memorization-timescale results (Bonnaire et al.; Favero
et al.), and the theory of the exact CFM minimizer (Bertrand et al.) predicts a
terminal state on small data — but that predicted state is *memorization*: velocity
diverging toward training points, samples becoming copies. Our flows never approach
it: novelty flattens near 2.0 (minimum ≈ 0.7, above τ) right up to the catastrophe,
and the terminal state is the opposite pole — no transport at all. We name the
phenomenon **velocity extinction** to distinguish it from LIRF's "velocity field
collapse" (degeneration into point attractors *at* the training samples, a
memorization-flavored concentration): extinction is a constant field, empirically
distinguishable in one probe. Mechanistically the loss discontinuity resembles an
optimizer catastrophe — a sharp minimum on too-few latents losing stability and the
model falling into the trivial predict-the-mean basin — but we characterize it
behaviorally and leave causal analysis open.

<figure>
  <img src="/assets/knowledge/canonicalize-then-generate/fig4-collapse-cliff.png" alt="The collapse cliff: N&amp;P and novelty vs training steps">
  <figcaption>Figure 4 — velocity extinction (k=256 cond@0.97, seed 0, n=1024 per point). Top: N&amp;P@1× rises, saturates far above the interpolation bar, and dies discontinuously (open marker: velocity ≈ 0). Bottom: sample novelty declines as training lengthens; the dead point (open) is not comparable — untransported noise. Shaded band: the failure boundary, pinned by telemetry to (70k, 71k].</figcaption>
</figure>

<figure>
  <img src="/assets/knowledge/canonicalize-then-generate/fig5-velocity-extinction.png" alt="Velocity extinction telemetry: loss and probe velocity-norm vs training step at three zoo sizes">
  <figcaption>Figure 5 — the law and its gate, from training telemetry. Top: training loss for three zoo sizes; the two converged runs jump discontinuously to the trivial loss (dashed) at n-proportional times (dotted verticals); the data-starved n=704 run never converges and never collapses. Bottom: the fixed-path velocity-norm probe — a healthy transport field one probe interval before a constant, dead one.</figcaption>
</figure>

Practical guidance for small zoos follows directly: budget ≈26k epochs as a hard
horizon (or instrument the one-line velocity-norm probe and stop on its collapse);
pick the operating point by the novelty depth required — earlier stops buy novelty,
later stops buy pass rate; and never trust a long-trained small-zoo flow without an
extinction check, because a dead flow's samples are silently well-formed noise.

## 6. Limitations

(1) Two architecture families at small scale. The CNN replication (§5.7) answers the
layered-quotient question — coordinate-descent alignment converges in ≤4 sweeps and the
per-lineage premise (SGD never permutes) holds a third time — but the deepest network
here has two permutable layers; genuinely deep stacks, residual connections, and
normalization layers (whose symmetry groups differ) remain untested. Systems in the
canonicalize-then-generate lineage already canonicalize at ResNet/ViT scale and model
100M-parameter zoos (DeepWeightFlow — whose largest, BERT-scale zoo is compressed
rather than canonicalized); it is the *audit* that has not been run there, and we would welcome
it. (2) The MNIST @1× margin is ~2σ per seed (the fashion ≈10σ and CNN results carry
the weight). (3) Functional novelty is measured on in-distribution test data. (4) The
generator's absolute quality is codec-capped, and the ceiling theory itself is scoped
by §5.6 to canonicalized codecs; a learned non-linear codec is unexplored here — the
CNN ceiling plateau is the cleanest motivating case. (5) All tasks are small grayscale
classification; nothing here demonstrates the audit at scale. (6) The extinction law
rests on two zoo sizes of one configuration; the convergence gate is characterized
behaviorally (loss floor), not causally, and the n=704 non-collapse is bounded only to
60k steps. (7) The soup's deep-τ dominance is observed on one architecture family; the
division of labor between fixed arithmetic and learned generators in the quotient may
be rig-dependent in ways these three rigs cannot resolve. (8) Raw-space novelty (the
§5.4 none-row) is partly subspace-truncation distance — an inherent property of
scoring PCA-decoded candidates against full-dimensional networks.

## 7. Discussion

The field's memorization problem and its evaluation problem are the same problem seen
from two sides: raw weight space over-counts functions, so generators trained on it
memorize orbit representatives, and metrics computed on it mistake orbit motion for
novelty. Quotienting the symmetries addresses both sides at once — cheaply, before any
model is trained, with any generative architecture downstream — and the field has
already begun adopting it. What it had not done is measure what the quotient buys
under a criterion memorization cannot game. The audit's answer is larger than the
generator question that motivated it: **canonicalization is the enabling object, and
the learned flow is one of its instruments, not its point.** The quotient revives the
entire candidate family — including a 16-network average that, on the conv rig,
outscores every learned model in the deep-novelty regime. An evaluation that only
reported accuracy would have crowned the flow and never seen the soup; an evaluation
without the trivial family would have credited the flow with a corner a weighted
average owns. The learned generator still earns real keep — the standard-threshold
corner on every rig, the only steerable dial, and everything on the MLP rigs — but the
honest scoreboard is mixed, and the mixture is the finding. Two directions follow.
Near: the extinction law (§5.8) makes small-zoo training budgets predictable, and a
learned codec may lift the ceiling that caps every flow cell. Far: adapter space —
LoRA factor pairs carry a rotation gauge exactly analogous to our permutations, at a
scale where generated artifacts are practically useful, and where the audit (bar,
soup, extinction check and all) should travel intact. If "canonicalize, then generate"
survives that transplant — with whichever instrument the scoreboard favors — it
graduates from a recipe to a principle.

## Reproducibility statement

Every number above is reproducible from the project repository: zoos re-derive from recorded
seeds; canonicalizers are exact and test-pinned (function preservation, idempotence,
quotient property, LAP-vs-brute-force); all GPU training and evaluation ran through a
governed queue whose job rows carry cryptographic state pins — the flagship training
run was verified **bit-identical** to an uninterrupted control after surviving a
backend crash, a cooperative preemption, and four checkpoint slices (hash-equal final
weights and RNG state). Training telemetry (decimated loss + a fixed-input
velocity-norm probe, RNG-isolated and itself covered by the bit-identical-resume
tests) provides the §5.8 mechanism traces. Experiment provenance (configs, job IDs,
event timelines) is recorded per-result in an append-only research journal with
pre-registered predictions — including the three pre-registrations this paper reports
as missed (§5.4's third outcome, §5.7's scale-leg null, §5.8's n=704 non-collapse).
The repository and experiment journal are available on request.

## References

*(All quotations are pinned to published versions: the Zeng et al. quotes are
verbatim against the CVPR 2026 camera-ready PDF, and the DeepWeightFlow quote against
its v2 Table 5 caption. Bibliographic records were verified against arXiv, proceedings
pages, and OpenReview as of 2026-07-15.)*

1. Peebles, Radosavovic, Brooks, Efros, Malik. *Learning to Learn with Generative Models
   of Neural Network Checkpoints.* arXiv:2209.12892 (2022). —
   23M checkpoints across per-task models; permutation handled by augmentation only.
2. Wang, Tang, Zeng, Yin, Xu, Zhou, Zang, Darrell, Liu, You. *Neural Network Diffusion.*
   arXiv:2402.13144 (2024).
3. Erkoç, Ma, Shan, Nießner, Dai. *HyperDiffusion: Generating Implicit Neural Fields
   with Weight-Space Diffusion.* ICCV 2023. arXiv:2303.17015.
4. Schürholt, Taskiran, Knyazev, Giró-i-Nieto, Borth. *Model Zoos: A Dataset of Diverse
   Populations of Neural Network Models.* NeurIPS 2022 Datasets & Benchmarks.
   arXiv:2209.14764.
5. Schürholt, Mahoney, Borth. *Towards Scalable and Versatile Weight Space Learning*
   (SANE). ICML 2024, PMLR 235. arXiv:2406.09997.
6. Zeng, Yin, Xu, Liu. *Generative Modeling of Weights: Generalization or Memorization?*
   CVPR 2026 (Highlight), pp. 41974–41984. arXiv:2506.07998. — quotes pinned verbatim
   to the camera-ready PDF (the open-access HTML abstract differs in comma placement;
   cite the PDF). Three authors overlap with p-diff (informed self-critique).
7. Ainsworth, Hayase, Srinivasa. *Git Re-Basin: Merging Models modulo Permutation
   Symmetries.* ICLR 2023. arXiv:2209.04836.
8. Jordan, Sedghi, Saukh, Entezari, Neyshabur. *REPAIR: REnormalizing Permuted
   Activations for Interpolation Repair.* ICLR 2023. arXiv:2211.08403.
9. Frankle, Dziugaite, Roy, Carbin. *Linear Mode Connectivity and the Lottery Ticket
   Hypothesis.* ICML 2020. arXiv:1912.05671.
10. Entezari, Sedghi, Saukh, Neyshabur. *The Role of Permutation Invariance in Linear
    Mode Connectivity of Neural Networks.* ICLR 2022. arXiv:2110.06296.
11. Zhou, Yang, et al. *Permutation Equivariant Neural Functionals.* NeurIPS 2023.
    arXiv:2302.14040.
12. Navon, Shamsian, et al. *Equivariant Architectures for Learning in Deep Weight
    Spaces.* ICML 2023, PMLR 202. arXiv:2301.12780.
13. Lipman, Chen, Ben-Hamu, Nickel, Le. *Flow Matching for Generative Modeling.*
    ICLR 2023. arXiv:2210.02747.
14. Stock, Graham, Gribonval, Jégou. *Equi-normalization of Neural Networks* (ENorm).
    ICLR 2019. arXiv:1902.10416. — proves iterative balancing converges to a unique
    canonical parameterization.
15. Neyshabur, Salakhutdinov, Srebro. *Path-SGD: Path-Normalized Optimization in Deep
    Neural Networks.* NeurIPS 2015. arXiv:1506.02617.
16. Charakorn, Cetin, Tang, Lange (Sakana AI). *Text-to-LoRA: Instant Transformer
    Adaption.* ICML 2025, PMLR 267:7485–7514. arXiv:2506.06105.
17. Gupta, Biggs, Laber, Shafi, Walters, Paul. *DeepWeightFlow: Re-Basined Flow
    Matching for Generating Neural Network Weights.* ICLR 2026. arXiv:2601.05052
    (v1 Jan 2026, v2 Apr 2026; quoted text = the v2 Table 5 caption, verified).
18. Erdogan. *Geometric Flow Models over Neural Network Weights.* MSc thesis, TU
    Munich (2025). arXiv:2504.03710. — Re-Basin + Pittorino-style scale normalization
    before flow matching; three flow geometries.
19. Pittorino, Ferraro, Perugini, Feinauer, Baldassi, Zecchina. *Deep Networks on
    Toroids: Removing Symmetries Reveals the Structure of Flat Regions in the
    Landscape Geometry.* ICML 2022, PMLR 162:17759–17781. arXiv:2202.03038.
20. Boufalis, Carrasco-Pollo, Rosenthal, Terres-Caballero, García-Castellanos.
    *Symmetry-Aware Graph Metanetwork Autoencoders: Model Merging through Parameter
    Canonicalization.* TAG-DS 2025, PMLR 321:217–235 (2026). arXiv:2511.12601. —
    full-text verified: merging only; generative use of the latents appears once as a
    hypothetical downstream direction (their §6.1), never executed.
21. Z. Wang, P. Wang, K. Wang. *Position: Weight Space Should Be a First-Class
    Generative AI Modality.* ICML 2026 (Position Paper track), PMLR 306.
    arXiv:2605.18632. — §3.5 states the novelty requirement this paper's protocol
    operationalizes; quote verified verbatim (elision = its two inline citations).
22. K. Wang, Tang, Zhao, Schürholt, Z. Wang, You. *Scaling Up Parameter Generation:
    A Recurrent Diffusion Approach* (RPG). NeurIPS 2025. arXiv:2501.11587 (preprint
    title: *Recurrent Diffusion for Large-Scale Parameter Generation*).
23. Bonnaire, Urfin, Biroli, Mézard. *Why Diffusion Models Don't Memorize: The Role of
    Implicit Dynamical Regularization in Training.* NeurIPS 2025 (Oral; Best Paper
    Award). arXiv:2505.17638.
24. Favero, Sclocchi, Wyart. *Bigger Isn't Always Memorizing: Early Stopping
    Overparameterized Diffusion Models.* TMLR 2026. arXiv:2505.16959.
25. Bertrand, Gagneux, Massias, Emonet. *On the Closed-Form of Flow Matching:
    Generalization Does Not Arise from Target Stochasticity.* NeurIPS 2025 (Oral).
    arXiv:2506.03719. — exact CFM minimizer reproduces training samples; velocity
    diverges toward nearest training point.
26. S. Li, Hou, Liao, Gao. *Latent Iterative Refinement Flow: A Geometric Constrained
    Approach for Few-Shot Generation* (LIRF). arXiv:2509.19903 (v2 Jan 2026; preprint).
    — "velocity field collapse" as point-attractor degeneration; disambiguated from
    velocity extinction in §5.8.
27. Sareen, Levy, Mondal, Kaba, Akhound-Sadegh, Ravanbakhsh. *Symmetry-Aware
    Generative Modeling through Learned Canonicalization.* NeurReps Workshop @ NeurIPS
    2024. arXiv:2501.07773. — molecular domain.
28. Saragih, Cao, Balaji, Santhosh. *Flow to Learn: Flow Matching on Neural Network
    Parameters* (FLoWN). ICLR 2025 Workshop on Neural Network Weights as a New Data
    Modality. arXiv:2503.19371.
29. L. Li, Hong, Zhang, Lin, J. Li, Tang, Liang. *The Velocity Deficit: Initial Energy
    Injection for Flow Matching.* ICML 2026. arXiv:2605.14819. — converged, large-data
    velocity-magnitude bias; contrasted with velocity extinction in §2.
30. Wortsman, Ilharco, Gadre, Roelofs, Gontijo-Lopes, Morcos, Namkoong, Farhadi,
    Carmon, Kornblith, Schmidt. *Model Soups: Averaging Weights of Multiple Fine-Tuned
    Models Improves Accuracy Without Increasing Inference Time.* ICML 2022.
    arXiv:2203.05482.
31. Zhou, Chen, Z. Li, J. Wang, Jiang, P. Li, Yu, M. Zhang, Bates, Jaakkola.
    *Rethinking Diffusion Models with Symmetries through Canonicalization with
    Applications to Molecular Graph Generation.* arXiv:2602.15022 (2026). — the
    general canonicalize-then-generate theory: correctness, expressivity over
    equivariant architectures, faster training.
32. T. Li, Shen. *Scaling Linear Mode Connectivity and Merging to Billion Parameter
    Pretrained Transformers.* arXiv:2606.23607 (2026).
33. Shou. *ODE-free Neural Flow Matching for One-Step Generative Modeling.*
    arXiv:2604.06413 (2026). — "mean collapse" from inconsistent noise–data pairings;
    delineated from velocity extinction in §2.
34. Ito, Yamada, Chijiwa, Kumagai. *Do We Really Need Permutations? Impact of Model
    Width on Linear Mode Connectivity.* ICLR 2026. arXiv:2510.08023.
