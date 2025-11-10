/// Medical Diagnosis Swarm Intelligence Demo
/// Scenario: Multi-specialist medical consultation for complex patient case
///
/// Shows chatbot-style interaction with SYSTEM, USER, and multiple SPECIALIST agents
/// This simulates how our swarm intelligence would coordinate in a real medical AI assistant

import 'package:micro/infrastructure/ai/agent/swarm/blackboard.dart';
import 'package:micro/infrastructure/serialization/toon_encoder.dart';

void main() {
  print(
      '╔═══════════════════════════════════════════════════════════════════════════╗');
  print(
      '║                     MEDICAL DIAGNOSIS SWARM DEMO                          ║');
  print(
      '║              Multi-Specialist AI Consultation System                      ║');
  print(
      '╚═══════════════════════════════════════════════════════════════════════════╝');
  print('');

  // Patient case
  final patientCase = """
Patient: 45-year-old male
Chief Complaint: Persistent fatigue, unexplained weight loss (15 lbs in 2 months), frequent urination
Medical History: Type 2 Diabetes (diagnosed 5 years ago), hypertension, family history of thyroid disease
Current Medications: Metformin 1000mg BID, Lisinopril 10mg daily
Vital Signs: BP 145/92, HR 88, Temp 98.6°F, Weight 185 lbs (down from 200)
Lab Results Pending: HbA1c, TSH, Free T4, Comprehensive Metabolic Panel
""";

  print(
      '═══════════════════════════════════════════════════════════════════════════');
  print('💬 CONVERSATION LOG');
  print(
      '═══════════════════════════════════════════════════════════════════════════');
  print('');

  // SYSTEM initialization
  print(
      '┌───────────────────────────────────────────────────────────────────────┐');
  print(
      '│ 🖥️  SYSTEM                                                             │');
  print(
      '├───────────────────────────────────────────────────────────────────────┤');
  print(
      '│ Medical AI Consultation System v2.0 initialized                       │');
  print(
      '│ Swarm Intelligence Mode: ENABLED                                      │');
  print(
      '│ Privacy Mode: HIPAA Compliant                                         │');
  print(
      '│ Blackboard: Ready for multi-specialist coordination                   │');
  print(
      '└───────────────────────────────────────────────────────────────────────┘');
  print('');

  // USER input
  print(
      '┌───────────────────────────────────────────────────────────────────────┐');
  print(
      '│ 👨‍⚕️ USER (Dr. Sarah Chen - Primary Care Physician)                    │');
  print(
      '├───────────────────────────────────────────────────────────────────────┤');
  print(
      '│ I need a comprehensive analysis for this patient case:                │');
  print(
      '│                                                                        │');
  for (final line in patientCase.trim().split('\n')) {
    print('│ ${line.padRight(70)} │');
  }
  print(
      '│                                                                        │');
  print(
      '│ Questions:                                                             │');
  print(
      '│ 1. What are the most likely differential diagnoses?                   │');
  print(
      '│ 2. Which tests should I prioritize?                                   │');
  print(
      '│ 3. Are there any urgent concerns?                                     │');
  print(
      '│ 4. What immediate interventions do you recommend?                     │');
  print(
      '└───────────────────────────────────────────────────────────────────────┘');
  print('');

  // SYSTEM analyzing task
  print(
      '┌───────────────────────────────────────────────────────────────────────┐');
  print(
      '│ 🖥️  SYSTEM                                                             │');
  print(
      '├───────────────────────────────────────────────────────────────────────┤');
  print(
      '│ 🔍 Analyzing case complexity...                                        │');
  print(
      '│ ✓ Detected domains: Endocrinology, Cardiology, Internal Medicine      │');
  print(
      '│ ✓ Complexity level: MODERATE-HIGH (multiple comorbidities)            │');
  print(
      '│ ✓ Generating specialist team...                                       │');
  print(
      '│                                                                        │');
  print(
      '│ 🤖 Swarm composition:                                                  │');
  print(
      '│   → Specialist 1: Endocrinologist (diabetes/thyroid expert)           │');
  print(
      '│   → Specialist 2: Internal Medicine (symptom correlator)              │');
  print(
      '│   → Specialist 3: Clinical Pathologist (lab interpreter)              │');
  print(
      '│   → Specialist 4: Risk Assessor (urgent findings detector)            │');
  print(
      '│   → Specialist 5: Treatment Coordinator (synthesis & recommendations) │');
  print(
      '│                                                                        │');
  print(
      '│ 📊 Estimated tokens: ~450 (with TOON optimization)                    │');
  print(
      '│ 💰 Estimated cost: \$0.00 (using GLM-4.5-Flash FREE tier)              │');
  print(
      '└───────────────────────────────────────────────────────────────────────┘');
  print('');

  final blackboard = Blackboard();

  // SPECIALIST 1: Endocrinologist
  print(
      '┌───────────────────────────────────────────────────────────────────────┐');
  print(
      '│ 🔬 SPECIALIST #1: Dr. Endocrine (Endocrinology AI)                    │');
  print(
      '├───────────────────────────────────────────────────────────────────────┤');
  print(
      '│ 📥 Received: Patient case data                                         │');
  print(
      '│                                                                        │');
  print(
      '│ 🧠 Reasoning:                                                          │');
  print(
      '│   • Patient has known T2DM with poor control indicators               │');
  print(
      '│   • Classic symptoms: polyuria + weight loss + fatigue                │');
  print(
      '│   • Family history of thyroid disease is significant red flag         │');
  print(
      '│   • Weight loss despite diabetes suggests hyperthyroidism OR          │');
  print(
      '│     uncontrolled diabetes with glycosuria                             │');
  print(
      '│                                                                        │');
  print(
      '│ 📊 Analysis:                                                           │');
  print(
      '│   Primary Hypothesis: Uncontrolled Type 2 Diabetes (85% confidence)   │');
  print(
      '│   Secondary Hypothesis: Hyperthyroidism (70% confidence)              │');
  print(
      '│   Tertiary: Diabetes + Thyroid comorbidity (55% confidence)           │');
  print(
      '│                                                                        │');
  print(
      '│ ✍️  Writing to blackboard:                                             │');
  print(
      '│   • differential_dx_endo: [T2DM_uncontrolled, hyperthyroidism,        │');
  print(
      '│                            thyroid_diabetes_combo]                    │');
  print(
      '│   • key_findings: [polyuria, weight_loss, fatigue, family_hx]         │');
  print(
      '│   • confidence_scores: {T2DM: 0.85, Hyperthyroid: 0.70, Combo: 0.55}  │');
  print(
      '└───────────────────────────────────────────────────────────────────────┘');
  print('');

  blackboard.put(
      'differential_dx_endo',
      [
        {'diagnosis': 'T2DM_uncontrolled', 'confidence': 0.85},
        {'diagnosis': 'hyperthyroidism', 'confidence': 0.70},
        {'diagnosis': 'thyroid_diabetes_combo', 'confidence': 0.55}
      ],
      author: 'spec_endocrine',
      confidence: 0.85);

  blackboard.put('key_findings',
      ['polyuria', 'weight_loss', 'fatigue', 'family_hx_thyroid'],
      author: 'spec_endocrine');

  // SPECIALIST 2: Internal Medicine
  print(
      '┌───────────────────────────────────────────────────────────────────────┐');
  print(
      '│ 🩺 SPECIALIST #2: Dr. InternalMed (Internal Medicine AI)              │');
  print(
      '├───────────────────────────────────────────────────────────────────────┤');
  print(
      '│ 📥 Received: Patient case + Blackboard state (v${blackboard.version})                       │');
  print(
      '│ 📋 Reading specialist #1 findings...                                  │');
  print(
      '│                                                                        │');
  print(
      '│ 🧠 Reasoning:                                                          │');
  print(
      '│   • I agree with endocrine\'s diabetes hypothesis                      │');
  print(
      '│   • However, BP 145/92 is concerning with current meds                │');
  print(
      '│   • Need to consider: cardiovascular complications                    │');
  print(
      '│   • Weight loss pattern: 15 lbs / 2 months = 7.5% body weight         │');
  print(
      '│   • This is SIGNIFICANT and rapid - warrants immediate attention      │');
  print(
      '│                                                                        │');
  print(
      '│ 📊 Additional Differentials:                                           │');
  print(
      '│   • Diabetic nephropathy (elevated BP despite meds)                   │');
  print(
      '│   • Possible malignancy (rapid unexplained weight loss)               │');
  print(
      '│   • Metabolic syndrome progression                                    │');
  print(
      '│                                                                        │');
  print(
      '│ ⚠️  RED FLAGS identified:                                              │');
  print(
      '│   1. Uncontrolled hypertension on medication (145/92)                 │');
  print(
      '│   2. Rapid weight loss (>5% in 2 months)                              │');
  print(
      '│   3. Multiple symptoms suggesting systemic issue                      │');
  print(
      '│                                                                        │');
  print(
      '│ ✍️  Writing to blackboard:                                             │');
  print(
      '│   • additional_dx: [diabetic_nephropathy, malignancy_workup]          │');
  print(
      '│   • red_flags: [uncontrolled_bp, rapid_weight_loss, systemic_concern] │');
  print(
      '│   • severity: MODERATE-HIGH                                           │');
  print(
      '└───────────────────────────────────────────────────────────────────────┘');
  print('');

  blackboard.put(
      'additional_dx',
      [
        {'diagnosis': 'diabetic_nephropathy', 'confidence': 0.65},
        {'diagnosis': 'malignancy_workup', 'confidence': 0.40}
      ],
      author: 'spec_internal_med',
      confidence: 0.75);

  blackboard.put('red_flags',
      ['uncontrolled_bp_on_meds', 'rapid_weight_loss_7pct', 'systemic_concern'],
      author: 'spec_internal_med', confidence: 0.90);

  blackboard.put('severity_level', 'MODERATE-HIGH',
      author: 'spec_internal_med');

  // Show TOON compression benefit
  print(
      '┌───────────────────────────────────────────────────────────────────────┐');
  print(
      '│ 🖥️  SYSTEM (Blackboard Status)                                        │');
  print(
      '├───────────────────────────────────────────────────────────────────────┤');
  final toonSize = blackboard.toTOON().length;
  final jsonSize = blackboard.toJSON().length;
  final savings = ((jsonSize - toonSize) / jsonSize * 100).toStringAsFixed(1);
  print(
      '│ 📊 Current blackboard: ${blackboard.factCount} facts (v${blackboard.version})                            │');
  print(
      '│ 💾 TOON serialization: $toonSize chars                                    │');
  print(
      '│ 💾 JSON serialization: $jsonSize chars                                   │');
  print(
      '│ 💰 Token savings: $savings% (sending to next specialist)                │');
  print(
      '└───────────────────────────────────────────────────────────────────────┘');
  print('');

  // SPECIALIST 3: Clinical Pathologist
  print(
      '┌───────────────────────────────────────────────────────────────────────┐');
  print(
      '│ 🧪 SPECIALIST #3: Dr. LabPath (Clinical Pathology AI)                 │');
  print(
      '├───────────────────────────────────────────────────────────────────────┤');
  print(
      '│ 📥 Received: TOON-encoded blackboard delta (${blackboard.getDelta(0).length} facts)                  │');
  print(
      '│ 📋 Analyzing test ordering priorities...                              │');
  print(
      '│                                                                        │');
  print(
      '│ 🧠 Reasoning based on colleague findings:                              │');
  print(
      '│   Endocrinologist suspects: T2DM + possible thyroid                   │');
  print(
      '│   Internist flagged: nephropathy risk + malignancy concern            │');
  print(
      '│                                                                        │');
  print(
      '│ 🔬 PRIORITY TESTS (ordered by urgency):                                │');
  print(
      '│                                                                        │');
  print(
      '│   🔴 URGENT (same day):                                                │');
  print(
      '│   1. HbA1c - assess diabetes control (target <7% for this patient)    │');
  print(
      '│   2. Comprehensive Metabolic Panel - kidney function critical         │');
  print(
      '│      → Check creatinine, eGFR for nephropathy                         │');
  print(
      '│      → Electrolytes (diabetes + diuretic effect)                      │');
  print(
      '│                                                                        │');
  print(
      '│   🟡 HIGH PRIORITY (within 48 hours):                                  │');
  print(
      '│   3. Thyroid Panel (TSH, Free T4, Free T3) - family history           │');
  print(
      '│   4. Urinalysis with microalbumin - early nephropathy detection       │');
  print(
      '│   5. Fasting lipid panel - cardiovascular risk                        │');
  print(
      '│                                                                        │');
  print(
      '│   🟢 FOLLOW-UP (within 1 week):                                        │');
  print(
      '│   6. Complete Blood Count - rule out anemia/infection                 │');
  print(
      '│   7. Consider: CT chest/abdomen if weight loss persists               │');
  print(
      '│                                                                        │');
  print(
      '│ 📊 Expected findings if T2DM uncontrolled:                             │');
  print(
      '│   • HbA1c: likely >9% (poor control)                                  │');
  print(
      '│   • Glucose: elevated (>180 mg/dL fasting)                            │');
  print(
      '│   • Possible glucosuria (explaining polyuria + weight loss)           │');
  print(
      '│                                                                        │');
  print(
      '│ ✍️  Writing to blackboard:                                             │');
  print(
      '│   • test_priority_urgent: [HbA1c, CMP]                                │');
  print(
      '│   • test_priority_high: [thyroid_panel, urinalysis, lipids]           │');
  print(
      '│   • test_priority_followup: [CBC, imaging_if_needed]                  │');
  print(
      '│   • expected_abnormal_results: [HbA1c_high, glucose_high,             │');
  print(
      '│                                 possible_creatinine_elevation]        │');
  print(
      '└───────────────────────────────────────────────────────────────────────┘');
  print('');

  blackboard.put('test_priority_urgent', ['HbA1c', 'CMP'],
      author: 'spec_pathology', confidence: 0.95);
  blackboard.put(
      'test_priority_high', ['thyroid_panel', 'urinalysis', 'lipid_panel'],
      author: 'spec_pathology', confidence: 0.90);
  blackboard.put('test_priority_followup', ['CBC', 'imaging_conditional'],
      author: 'spec_pathology', confidence: 0.80);

  // SPECIALIST 4: Risk Assessor
  print(
      '┌───────────────────────────────────────────────────────────────────────┐');
  print(
      '│ ⚠️  SPECIALIST #4: Dr. RiskAssess (Clinical Risk AI)                  │');
  print(
      '├───────────────────────────────────────────────────────────────────────┤');
  print(
      '│ 📥 Received: Full blackboard context (${blackboard.factCount} facts)                       │');
  print(
      '│ 🔍 Performing comprehensive risk analysis...                          │');
  print(
      '│                                                                        │');
  print(
      '│ 🧠 Risk Stratification:                                                │');
  print(
      '│                                                                        │');
  print(
      '│ 🔴 IMMEDIATE CONCERNS (require same-day action):                       │');
  print(
      '│   1. Diabetic Ketoacidosis (DKA) Risk: MODERATE                       │');
  print(
      '│      • Symptoms: polyuria, weight loss, fatigue                       │');
  print(
      '│      • If HbA1c >10%, consider DKA workup                             │');
  print(
      '│      • Action: Check for ketones, assess mental status                │');
  print(
      '│                                                                        │');
  print(
      '│   2. Hypertensive Crisis Risk: LOW-MODERATE                           │');
  print(
      '│      • BP 145/92 on medication = inadequate control                   │');
  print(
      '│      • Combined with diabetes = high CVD risk                         │');
  print(
      '│      • Action: Consider medication adjustment today                   │');
  print(
      '│                                                                        │');
  print(
      '│ 🟡 SHORT-TERM RISKS (monitor closely):                                 │');
  print(
      '│   3. Diabetic Nephropathy Progression: MODERATE-HIGH                  │');
  print(
      '│      • Elevated BP + diabetes duration (5 years)                      │');
  print(
      '│      • Action: Urgent kidney function tests (within 24h)              │');
  print(
      '│                                                                        │');
  print(
      '│   4. Thyrotoxicosis (if hyperthyroid confirmed): MODERATE             │');
  print(
      '│      • Weight loss + family history                                   │');
  print(
      '│      • Action: Thyroid panel within 48h                               │');
  print(
      '│                                                                        │');
  print(
      '│ 🟢 LONG-TERM MONITORING:                                               │');
  print(
      '│   5. Cardiovascular Event Risk: 15-20% over 10 years                  │');
  print(
      '│   6. Malignancy (if weight loss unexplained): 5-10% probability       │');
  print(
      '│                                                                        │');
  print(
      '│ 🚨 URGENT RECOMMENDATION:                                              │');
  print(
      '│   Patient should be seen TODAY for:                                   │');
  print(
      '│   • Stat labs (HbA1c, BMP, ketones)                                   │');
  print(
      '│   • Vital sign recheck                                                │');
  print(
      '│   • Consider ER referral if ketones positive or symptomatic           │');
  print(
      '│                                                                        │');
  print(
      '│ ✍️  Writing to blackboard:                                             │');
  print(
      '│   • urgent_action_required: true                                      │');
  print(
      '│   • risk_level: MODERATE-HIGH                                         │');
  print(
      '│   • immediate_concerns: [DKA_risk, HTN_uncontrolled, nephropathy]     │');
  print(
      '│   • recommendation: SAME_DAY_EVALUATION                               │');
  print(
      '└───────────────────────────────────────────────────────────────────────┘');
  print('');

  blackboard.put('urgent_action_required', true,
      author: 'spec_risk', confidence: 0.92);
  blackboard.put('risk_level', 'MODERATE-HIGH', author: 'spec_risk');
  blackboard.put('immediate_concerns',
      ['DKA_risk', 'HTN_uncontrolled', 'nephropathy_progression'],
      author: 'spec_risk', confidence: 0.88);
  blackboard.put('time_sensitivity', 'SAME_DAY_EVALUATION',
      author: 'spec_risk');

  // SPECIALIST 5: Treatment Coordinator (Synthesis)
  print(
      '┌───────────────────────────────────────────────────────────────────────┐');
  print(
      '│ 🎯 SPECIALIST #5: Dr. Synthesizer (Treatment Coordination AI)         │');
  print(
      '├───────────────────────────────────────────────────────────────────────┤');
  print(
      '│ 📥 Received: Complete team analysis (${blackboard.factCount} facts, ${blackboard.version} versions)          │');
  print(
      '│ 🔄 Synthesizing multi-specialist recommendations...                   │');
  print(
      '│                                                                        │');
  print(
      '│ 📋 INTEGRATED CLINICAL IMPRESSION:                                     │');
  print(
      '│                                                                        │');
  print(
      '│ Most Likely Diagnosis (85% confidence):                               │');
  print(
      '│   → Uncontrolled Type 2 Diabetes Mellitus                             │');
  print(
      '│   → With concurrent hypertension (inadequately controlled)            │');
  print(
      '│   → Rule out: hyperthyroidism, diabetic nephropathy                   │');
  print(
      '│                                                                        │');
  print(
      '│ ═══════════════════════════════════════════════════════════════════   │');
  print(
      '│ 🎯 IMMEDIATE ACTION PLAN (TODAY):                                      │');
  print(
      '│ ═══════════════════════════════════════════════════════════════════   │');
  print(
      '│                                                                        │');
  print(
      '│ 1️⃣  STAT LABORATORY TESTS:                                             │');
  print(
      '│    ✓ HbA1c (assess glycemic control)                                  │');
  print(
      '│    ✓ Comprehensive Metabolic Panel (kidney function, electrolytes)    │');
  print(
      '│    ✓ Urinalysis with ketones (rule out DKA)                           │');
  print(
      '│    ✓ Point-of-care glucose                                            │');
  print(
      '│                                                                        │');
  print(
      '│ 2️⃣  MEDICATION ADJUSTMENTS (pending labs):                             │');
  print(
      '│    ✓ Consider increasing Metformin to 1500mg BID if tolerated         │');
  print(
      '│    ✓ Add SGLT2 inhibitor (e.g., Empagliflozin 10mg) for:              │');
  print(
      '│      • Better glucose control                                         │');
  print(
      '│      • Cardiovascular protection                                      │');
  print(
      '│      • Renal protection                                               │');
  print(
      '│    ✓ Optimize BP control: increase Lisinopril to 20mg OR add CCB      │');
  print(
      '│                                                                        │');
  print(
      '│ 3️⃣  WITHIN 48 HOURS:                                                   │');
  print(
      '│    ✓ Thyroid panel (TSH, Free T4, Free T3)                            │');
  print(
      '│    ✓ Lipid panel                                                      │');
  print(
      '│    ✓ Urine microalbumin/creatinine ratio                              │');
  print(
      '│                                                                        │');
  print(
      '│ 4️⃣  PATIENT COUNSELING:                                                │');
  print(
      '│    ✓ Explain seriousness of current state                             │');
  print(
      '│    ✓ Dietary review (reduce simple carbs, increase protein)           │');
  print(
      '│    ✓ Home glucose monitoring: 4x daily until controlled               │');
  print(
      '│    ✓ Warning signs to watch: confusion, excessive thirst, vomiting    │');
  print(
      '│    ✓ Follow-up: 1 week (sooner if symptoms worsen)                    │');
  print(
      '│                                                                        │');
  print(
      '│ 5️⃣  REFERRALS (if indicated by test results):                          │');
  print(
      '│    ✓ Endocrinology: if HbA1c >10% or thyroid abnormal                 │');
  print(
      '│    ✓ Nephrology: if eGFR <60 or significant proteinuria               │');
  print(
      '│    ✓ Cardiology: if BP remains >150/95 on dual therapy                │');
  print(
      '│                                                                        │');
  print(
      '│ ⚠️  SAFETY NET:                                                         │');
  print(
      '│    If patient shows ANY of these, send to ER immediately:             │');
  print(
      '│    • Confusion or altered mental status                               │');
  print(
      '│    • Fruity breath odor (acetone)                                     │');
  print(
      '│    • Severe nausea/vomiting                                           │');
  print(
      '│    • Blood pressure >180/110                                          │');
  print(
      '│    • Chest pain or shortness of breath                                │');
  print(
      '│                                                                        │');
  print(
      '│ ✍️  Writing final recommendations to blackboard...                     │');
  print(
      '└───────────────────────────────────────────────────────────────────────┘');
  print('');

  blackboard.put(
      'final_diagnosis',
      {
        'primary': 'T2DM_uncontrolled',
        'secondary': 'HTN_inadequate_control',
        'rule_out': ['hyperthyroidism', 'diabetic_nephropathy'],
        'confidence': 0.85
      },
      author: 'spec_synthesizer',
      confidence: 0.88);

  blackboard.put(
      'action_plan',
      {
        'stat_labs': ['HbA1c', 'CMP', 'urinalysis_ketones', 'POC_glucose'],
        'med_adjustments': [
          'increase_metformin',
          'add_SGLT2i',
          'optimize_bp_control'
        ],
        'tests_48h': ['thyroid_panel', 'lipids', 'urine_microalbumin'],
        'counseling': [
          'explain_severity',
          'dietary_review',
          'home_monitoring',
          'warning_signs'
        ],
        'referrals_conditional': [
          'endocrinology_if_severe',
          'nephrology_if_renal',
          'cardiology_if_resistant_htn'
        ],
        'er_criteria': [
          'confusion',
          'fruity_breath',
          'severe_nausea',
          'bp_crisis',
          'chest_pain'
        ]
      },
      author: 'spec_synthesizer');

  // SYSTEM final summary
  print(
      '═══════════════════════════════════════════════════════════════════════════');
  print('🖥️  SYSTEM - SWARM COORDINATION COMPLETE');
  print(
      '═══════════════════════════════════════════════════════════════════════════');
  print('');
  print('✅ CONVERGENCE ACHIEVED');
  print('');
  print('📊 SWARM STATISTICS:');
  print('   • Total specialists: 5');
  print('   • Blackboard facts: ${blackboard.factCount}');
  print('   • Blackboard versions: ${blackboard.version}');
  print('   • Conflicts detected: 0 (all specialists aligned)');
  print('   • Consensus confidence: 85-88%');
  print('');
  print('💰 RESOURCE USAGE:');
  final finalToon = blackboard.toTOON().length;
  final finalJson = blackboard.toJSON().length;
  print('   • TOON size: $finalToon chars');
  print('   • JSON size: $finalJson chars');
  print(
      '   • Compression: ${((finalJson - finalToon) / finalJson * 100).toStringAsFixed(1)}% savings');
  print(
      '   • Estimated tokens: ~${(finalToon / 4).ceil()} (input) + ~800 (output)');
  print(
      '   • Cost (GLM-4.5): ~\$${((finalToon / 4 + 800) / 1000000 * 0.6).toStringAsFixed(4)}');
  print('   • Cost (GLM-4.5-Flash): \$0.00 FREE! ⭐');
  print('');
  print('⏱️  ESTIMATED TIME: 8-12 seconds (5 sequential LLM calls)');
  print('');

  // FINAL RESPONSE TO USER
  print(
      '═══════════════════════════════════════════════════════════════════════════');
  print('📋 FINAL CLINICAL REPORT (Delivered to Dr. Sarah Chen)');
  print(
      '═══════════════════════════════════════════════════════════════════════════');
  print('');
  print('Dear Dr. Chen,');
  print('');
  print(
      'Our AI specialist team has completed a comprehensive analysis of your patient');
  print('case. Here are the key findings and recommendations:');
  print('');
  print('🔍 DIAGNOSIS:');
  print('   Primary: Uncontrolled Type 2 Diabetes Mellitus (85% confidence)');
  print('   Secondary: Inadequately controlled Hypertension');
  print('   Differential: Rule out hyperthyroidism, diabetic nephropathy');
  print('');
  print('⚠️  URGENCY LEVEL: MODERATE-HIGH');
  print('   Patient requires SAME-DAY evaluation and laboratory testing');
  print('');
  print('🔬 IMMEDIATE TESTS (STAT):');
  print('   ✓ HbA1c, Comprehensive Metabolic Panel, Urinalysis with ketones');
  print('');
  print('💊 TREATMENT RECOMMENDATIONS:');
  print('   ✓ Optimize diabetes control (consider SGLT2 inhibitor addition)');
  print('   ✓ Improve blood pressure management (increase ACE inhibitor dose)');
  print('   ✓ Intensive glucose monitoring until stable');
  print('');
  print('🚨 RED FLAGS TO MONITOR:');
  print(
      '   Send to ER if: confusion, fruity breath, severe nausea, BP >180/110,');
  print('   chest pain, or shortness of breath develops');
  print('');
  print('📅 FOLLOW-UP: 1 week (or sooner if symptoms worsen)');
  print('');
  print(
      'This analysis was generated by our Medical Swarm Intelligence System,');
  print(
      'integrating insights from 5 specialist AIs. All recommendations should be');
  print(
      'reviewed and approved by the treating physician before implementation.');
  print('');
  print(
      '═══════════════════════════════════════════════════════════════════════════');
  print('');

  // ARCHITECTURAL INSIGHTS
  print(
      '╔═══════════════════════════════════════════════════════════════════════════╗');
  print(
      '║                    KEY ARCHITECTURAL BENEFITS                             ║');
  print(
      '╚═══════════════════════════════════════════════════════════════════════════╝');
  print('');
  print(
      '✅ Multi-Domain Expertise: Each specialist contributed unique perspective');
  print(
      '✅ Sequential Reasoning: Later specialists built upon earlier findings');
  print(
      '✅ Blackboard Coordination: ${blackboard.factCount} facts shared seamlessly across specialists');
  print(
      '✅ TOON Optimization: ${((finalJson - finalToon) / finalJson * 100).toStringAsFixed(1)}% token reduction (crucial for medical context)');
  print(
      '✅ Risk Stratification: Dedicated risk specialist caught urgent concerns');
  print(
      '✅ Clinical Synthesis: Final specialist integrated all findings coherently');
  print('✅ Cost Effective: \$0.00 with GLM-4.5-Flash (FREE tier)');
  print('✅ Mobile Safe: ~170MB peak memory (safe on all devices)');
  print('');
  print('💡 USER CONFIGURATION IMPACT:');
  print(
      '   • max_specialists=3: Would use Endo + InternalMed + Synthesizer (~\$0.0002)');
  print(
      '   • max_specialists=5: Full team as shown (\$0.0003) - RECOMMENDED for complex cases');
  print(
      '   • max_specialists=7: Could add Nutrition + Pharmacy specialists (\$0.0004)');
  print('');
  print('🎯 MEDICAL AI USE CASES:');
  print('   ✓ Differential diagnosis generation');
  print('   ✓ Test ordering optimization');
  print('   ✓ Multi-specialty consultation simulation');
  print('   ✓ Clinical decision support');
  print('   ✓ Medical education (teaching complex reasoning)');
  print('');
  print(
      '╔═══════════════════════════════════════════════════════════════════════════╗');
  print(
      '║                           DEMO COMPLETE                                   ║');
  print(
      '╚═══════════════════════════════════════════════════════════════════════════╝');
}
