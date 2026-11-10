---
name: experiment
description: Use NCBI or misc accessions for public datasets, or local knowledge in `graphify-out/`, to bioinformatically analyze a dataset.
---

# Experiment

## Hypothesis
1. Determine what hypothesis the sub-agent is testing.
2. Determine what data is needed to test it, and if it is available in the accessions below. If there is no data available, the hypothesis should be marked [?] and the sub-agent should be prompted to find a new hypothesis.

## Method
1. Detail out the bioinformatic analysis plan, including tools, parameters, and expected outputs. Include any preprocessing steps needed for the data.
2. Use pre-existing BioContainers on Quay.io, or if needed, generate a Docker image with pinned versions to accomplish the analysis. Store the BioContainer in `BioContainers/` or Dockerfile in `dockerfiles/` for reproducibility.

## Analysis
1. Download the datasets from NCBI or other specified accessions to `data/`. If the data is already present, verify its integrity.
2. Execute the analysis plan using the Docker image, ensuring that all steps are logged for reproducibility. Keep only the necessary outputs for the hypothesis test, and store them in a structured manner.

## Results
1. Summarize the results of the analysis, including any statistical tests performed, effect sizes, and confidence intervals. Include visualizations if applicable.
2. Compare the results against the hypothesis and determine if the hypothesis is supported or refuted. Document any unexpected findings or anomalies.
