SELECT DISTINCT amc.sub_code,
       samr.evidence_review_result,
       samr.version 
FROM LearnerSubmission ls 
JOIN SubmissionAssessment sa 
	ON sa.learner_submission_id = ls.id 
JOIN SubmissionAssessmentCriteria sac 
	ON sac.submission_assessment_id = sa.id 
JOIN AssessmentMeasurementCriteria amc 
	ON amc.assessment_grading_criteria_id  = sac.assessment_grading_criteria_id 
JOIN SubmissionAssessmentMeasurementResults samr 
	ON samr.submission_assessment_criteria_id = sac.id 
WHERE ls.learner_id = '3C92BCCE-A6A5-4478-8680-DF4056C77C13'
ORDER BY amc.sub_code ;