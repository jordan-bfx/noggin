---
name: experiment
description: Use NCBI or misc accessions for public datasets, or local knowledge in `graphify-out/`, to bioinformatically analyze a dataset.
---

# Experiment

## Hypothesis
1. Determine what hypothesis the sub-agent is testing.
2. Determine what data is needed to test it, and if it is available in the accessions below. If not, rely on primary literature found in the `graphify-out/` graph to support the hypothesis.

## Method
1. Detail out the bioinformatic analysis plan, including tools, parameters, and expected outputs. Include any preprocessing steps needed for the data.
2. Generate a Docker image with all dependencies to accomplish the analysis. Store the Dockerfile in `dockerfiles/` for reproducibility.

## Analysis
1. Download the datasets from NCBI or other specified accessions to the project root. If the data is already present, verify its integrity.
2. Execute the analysis plan using the Docker image, ensuring that all steps are logged for reproducibility. Keep only the necessary outputs for the hypothesis test, and store them in a structured manner.

## Results
1. Summarize the results of the analysis, including any statistical tests performed, effect sizes, and confidence intervals. Include visualizations if applicable.
2. Compare the results against the hypothesis and determine if the hypothesis is supported or refuted. Document any unexpected findings or anomalies.

## Record
1. Append a detailed entry to `research.log` with the following structure:
```
## <YYYY-MM-DD HH:MM> <topic> (round k/N)
- hypothesis: <written before looking at results>
- method: <data, tests, every test run, including the ones that found nothing>
- result: <effect size, n, uncertainty; null results count>
- evidence: <file paths, DOIs>
- next: <follow-up or open question>
```


