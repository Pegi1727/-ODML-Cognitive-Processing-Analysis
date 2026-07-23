# ==============================================================================
# Project: Output-Driven Multilingual Learning (ODML) Longitudinal Study
# Script: 02_lmm_analysis.R
# Author: Dr. Pegah Marikh
# Description: Fits Linear Mixed-Effects Models (LMMs) for linguistic accuracy,
#              speech onset latency, and cognitive load (NASA-TLX).
#              Includes post-hoc pairwise contrasts and diagnostic plotting.
# ==============================================================================

# 1. Load Required Libraries ---------------------------------------------------
library(lme4)        # For Linear Mixed-Effects Models
library(lmerTest)    # For p-value estimation (Satterthwaite's approximation)
library(emmeans)     # For post-hoc estimated marginal means and contrasts
library(performance) # For computing Marginal and Conditional R2
library(ggplot2)     # For high-quality data visualization
library(dplyr)       # For data manipulation

# 2. Load and Prepare Data ----------------------------------------------------
# Replace 'data_processed.csv' with your actual clean data file path
data <- read.csv("data/processed/data_processed.csv")

# Ensure categorical factors are correctly formatted and reference levels set
data$InstructionalMethod <- factor(data$InstructionalMethod, levels = c("Control", "ODML"))
data$Time <- factor(data$Time, levels = c("Pretest", "Immediate_Posttest", "Delayed_1Month"))
data$Participant <- as.factor(data$Participant)
data$Item <- as.factor(data$Item)

# 3. Model 1: Linguistic Accuracy (%) ----------------------------------------
cat("\n--- Running LMM for Linguistic Accuracy ---\n")

# Model formulation with random intercepts for Participants and Items
model_accuracy <- lmer(
  LinguisticAccuracy ~ InstructionalMethod * Time + 
    (1 | Participant) + 
    (1 | Item), 
  data = data, 
  REML = TRUE
)

# Output summary (contains beta coefficients, SE, t-values, and p-values)
print(summary(model_accuracy))

# Compute R-squared (Marginal R2 / Conditional R2)
print(model_performance(model_accuracy))

# 3.1 Post-hoc Pairwise Comparisons for Accuracy (Bonferroni Adjusted)
cat("\n--- Pairwise Comparisons: Linguistic Accuracy ---\n")
em_accuracy <- emmeans(model_accuracy, ~ InstructionalMethod | Time)
contrasts_accuracy <- pairs(em_accuracy, adjust = "bonferroni")
print(contrasts_accuracy)

# Contrast over time within ODML
em_time_odml <- emmeans(model_accuracy, ~ Time | InstructionalMethod)
contrasts_time_odml <- pairs(em_time_odml, adjust = "bonferroni")
print(contrasts_time_odml)


# 4. Model 2: Speech Onset Latency (ms) --------------------------------------
cat("\n--- Running LMM for Speech Onset Latency ---\n")

# Fitting Speech Onset Latency LMM
model_sol <- lmer(
  SpeechOnsetLatency ~ InstructionalMethod * Time + 
    (1 | Participant) + 
    (1 | Item), 
  data = data, 
  REML = TRUE
)

print(summary(model_sol))
print(model_performance(model_sol))

# 4.1 Post-hoc Pairwise Comparisons for Speech Onset Latency
em_sol <- emmeans(model_sol, ~ InstructionalMethod | Time)
contrasts_sol <- pairs(em_sol, adjust = "bonferroni")
print(contrasts_sol)


# 5. Model 3: Cognitive Load (NASA-TLX) ---------------------------------------
cat("\n--- Running LMM for Cognitive Load (NASA-TLX) ---\n")

# Note: Time points here reflect Phase (Intervention vs. Delayed Assessment)
data_tlx <- data %>% filter(Time %in% c("Immediate_Posttest", "Delayed_1Month"))
data_tlx$Time <- droplevels(data_tlx$Time)

model_tlx <- lmer(
  CognitiveLoad ~ InstructionalMethod * Time + 
    (1 | Participant), 
  data = data_tlx, 
  REML = TRUE
)

print(summary(model_tlx))
print(model_performance(model_tlx))

# 5.1 Post-hoc Pairwise Comparisons for NASA-TLX
em_tlx <- emmeans(model_tlx, ~ InstructionalMethod | Time)
contrasts_tlx <- pairs(em_tlx, adjust = "bonferroni")
print(contrasts_tlx)


# 6. Model Diagnostics and Residual Plots ------------------------------------
cat("\n--- Generating Diagnostic Plots ---\n")

# Check assumptions for the primary model (Linguistic Accuracy)
# 1. Residuals vs. Fitted values (Homoscedasticity check)
png("outputs/figures/diagnostic_residuals_vs_fitted.png", width = 800, height = 600)
plot(model_accuracy, type = c("p", "smooth"), 
     main = "Residuals vs. Fitted Values (Linguistic Accuracy)")
dev.off()

# 2. Normal Q-Q plot (Normality of residuals check)
png("outputs/figures/diagnostic_qqplot.png", width = 800, height = 600)
qqnorm(residuals(model_accuracy))
qqline(residuals(model_accuracy), col = "red", lwd = 2)
dev.off()

cat("\nAnalysis completed successfully. Figures and summaries exported to outputs/.\n")
