// E-Commerce Data Enrichment API - Data Models
// Phase 21: E-Commerce Data Enrichment Integration POC
// Section 21.1: Foundation & Infrastructure

// ============================================
// Common Types
// ============================================

export interface APIError {
  code: string
  message: string
  details?: Record<string, any>
}

export interface ResponseMetadata {
  request_id: string
  processing_time_ms: number
  api_version: string
  timestamp?: string
}

export interface APIResponse<T> {
  success: boolean
  data?: T
  error?: APIError
  metadata?: ResponseMetadata
}

export interface MarketSegmentMetadata {
  sample_size: number
  data_freshness: string
  geographic_coverage?: string
  data_version?: string
}

// ============================================
// Request Models
// ============================================

export interface UserSegment {
  segment_id: string
  geographic_region?: string
  category_preferences?: string[]
  demographics?: {
    age_range?: [number, number]
    interests?: string[]
  }
}

export interface ProductContext {
  category: string
  subcategory?: string
  price_range?: 'budget' | 'mid' | 'premium' | 'luxury'
}

export interface ProductQuantumState {
  category: string
  style?: string
  price?: 'budget' | 'mid' | 'premium' | 'luxury'
  features?: string[]
  attributes?: {
    energy_level?: number
    novelty?: number
    community_oriented?: number
  }
}

// Real-World Behavior Request
export interface RealWorldBehaviorRequest {
  user_segment: UserSegment
  product_context?: ProductContext
  requested_insights?: string[]
}

// Quantum Personality Request
export interface QuantumPersonalityRequest {
  user_segment: UserSegment
  product_quantum_state: ProductQuantumState
  requested_insights?: string[]
}

// Community Influence Request
export interface CommunityInfluenceRequest {
  user_segment: UserSegment
  product_category?: string
  requested_insights?: string[]
}

// ============================================
// Response Models - Real-World Behavior
// ============================================

export interface AverageDwellTime {
  value: number // minutes
  unit: string
  confidence: number
}

export interface ReturnVisitRate {
  value: number // 0.0-1.0
  interpretation: string
  confidence: number
}

export interface ExplorationTendency {
  value: number // 0.0-1.0
  interpretation: string
  confidence: number
}

export interface CommunityEngagement {
  value: number // 0.0-1.0
  interpretation: string
  confidence: number
}

export interface JourneyPatterns {
  typical_path: string[]
  frequency: string
  variability: number
}

export interface TimeSpentAnalysis {
  short_visits: number // < 15 minutes
  medium_visits: number // 15-60 minutes
  long_visits: number // > 60 minutes
}

export interface PurchaseDecisionFactor {
  factor: string
  weight: number
}

export interface ProductImplications {
  prefers_quality_over_price: {
    value: boolean
    confidence: number
  }
  values_community_products: {
    value: boolean
    confidence: number
  }
  likely_to_return_purchase: {
    value: number
    confidence: number
  }
  purchase_decision_factors: PurchaseDecisionFactor[]
}

export interface RealWorldBehaviorData {
  real_world_behavior: {
    average_dwell_time: AverageDwellTime
    return_visit_rate: ReturnVisitRate
    exploration_tendency: ExplorationTendency
    community_engagement: CommunityEngagement
    journey_patterns: JourneyPatterns
    time_spent_analysis: TimeSpentAnalysis
  }
  product_implications: ProductImplications
  market_segment_metadata: MarketSegmentMetadata
}

// ============================================
// Response Models - Quantum Personality
// ============================================

export interface QuantumCompatibility {
  score: number // 0.0-1.0
  interpretation: string
  confidence: number
  formula: string
}

export interface PersonalityDimension {
  value: number // 0.0-1.0
  interpretation?: string
  std_dev: number
  percentiles?: {
    p25: number
    p50: number
    p75: number
  }
}

export interface PersonalityProfile {
  '12_dimensions': Record<string, PersonalityDimension>
  archetype: string
  authenticity_score: number
}

export interface KnotCompatibility {
  score: number // 0.0-1.0
  jones_polynomial_match: number
  alexander_polynomial_match: number
  topological_similarity: number
  knot_type_match: string
  interpretation: string
}

export interface HighCompatibilityProduct {
  product_id: string
  compatibility_score: number
  reasoning: string
}

export interface CompatibilityBreakdown {
  style_match: number
  price_match: number
  feature_match: number
  personality_match: number
}

export interface ProductRecommendations {
  high_compatibility: HighCompatibilityProduct[]
  compatibility_breakdown: CompatibilityBreakdown
}

export interface QuantumPersonalityData {
  quantum_compatibility: QuantumCompatibility
  personality_profile: PersonalityProfile
  knot_compatibility: KnotCompatibility
  product_recommendations: ProductRecommendations
  market_segment_metadata: MarketSegmentMetadata
}

// ============================================
// Response Models - Community Influence
// ============================================

export interface InfluenceScore {
  value: number // 0.0-1.0
  interpretation: string
  confidence: number
}

export interface InfluenceNetwork {
  direct_connections: number
  indirect_connections: number
  community_reach: number
  network_density: number
}

export interface AI2AIInsights {
  average_compatibility: number
  connection_frequency: string
  learning_rate: number
}

export interface CommunityInfluencePatterns {
  influence_score: InfluenceScore
  community_size: number
  influence_network: InfluenceNetwork
  ai2ai_insights: AI2AIInsights
}

export interface CommunityDrivenPurchases {
  value: number // 0.0-1.0
  interpretation: string
  confidence: number
}

export interface TrendSetterScore {
  value: number // 0.0-1.0
  interpretation: string
  confidence: number
}

export interface ViralPotential {
  value: number // 0.0-1.0
  interpretation: string
  confidence: number
}

export interface SocialSharingTendency {
  value: number // 0.0-1.0
  interpretation: string
  confidence: number
}

export interface PurchaseBehavior {
  community_driven_purchases: CommunityDrivenPurchases
  trend_setter_score: TrendSetterScore
  viral_potential: ViralPotential
  social_sharing_tendency: SocialSharingTendency
}

export interface RecommendedMarketingStrategy {
  strategy: string
  effectiveness: number
  reasoning: string
}

export interface MarketingImplications {
  responds_to_community_endorsements: {
    value: boolean
    confidence: number
  }
  likely_to_share_purchases: {
    value: number
    confidence: number
  }
  influencer_potential: {
    value: number
    interpretation: string
    confidence: number
  }
  recommended_marketing_strategies: RecommendedMarketingStrategy[]
}

export interface CommunityInfluenceData {
  community_influence_patterns: CommunityInfluencePatterns
  purchase_behavior: PurchaseBehavior
  marketing_implications: MarketingImplications
  market_segment_metadata: MarketSegmentMetadata
}
