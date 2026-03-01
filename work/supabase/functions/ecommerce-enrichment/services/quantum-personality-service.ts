// Quantum Personality Enrichment Service
// Phase 21 Section 2: Core Endpoints

import type {
  QuantumPersonalityRequest,
  QuantumPersonalityData,
  QuantumCompatibility,
  PersonalityProfile,
  PersonalityDimension,
  KnotCompatibility,
  ProductRecommendations,
  HighCompatibilityProduct,
  CompatibilityBreakdown,
  MarketSegmentMetadata,
} from '../models.ts'

export class QuantumPersonalityService {
  constructor(private supabase: any) {}

  async getQuantumPersonality(
    request: QuantumPersonalityRequest
  ): Promise<QuantumPersonalityData> {
    const { user_segment, product_quantum_state } = request

    // Ensure segment exists
    await this.ensureSegmentExists(user_segment)

    // Aggregate personality profiles
    const { data: personalityData, error: personalityError } = await this.supabase.rpc(
      'aggregate_personality_profiles',
      { p_segment_id: user_segment.segment_id }
    )

    if (personalityError) {
      // If function doesn't exist or table doesn't exist, return default data
      if (personalityError.message?.includes('does not exist') || personalityError.message?.includes('relation')) {
        console.warn(`Database tables not available, returning default personality data: ${personalityError.message}`)
        return this.getDefaultPersonalityData(user_segment, product_quantum_state)
      }
      throw new Error(`Failed to aggregate personality: ${personalityError.message}`)
    }

    if (!personalityData || personalityData.error) {
      // If no data available, return defaults instead of error
      console.warn(`No personality data available for segment ${user_segment.segment_id}, returning defaults`)
      return this.getDefaultPersonalityData(user_segment, product_quantum_state)
    }

    // Parallelize independent calculations for better performance
    const [quantumCompatibility, knotCompatibility] = await Promise.all([
      Promise.resolve(this.calculateQuantumCompatibility(personalityData, product_quantum_state)),
      this.calculateKnotCompatibility(user_segment, product_quantum_state),
    ])

    // Generate product recommendations (depends on above calculations)
    const productRecommendations = this.generateProductRecommendations(
      quantumCompatibility,
      personalityData,
      product_quantum_state
    )

    // Format personality profile
    const personalityProfile: PersonalityProfile = {
      '12_dimensions': this.formatPersonalityDimensions(personalityData),
      archetype: personalityData.archetype || 'Aggregate',
      authenticity_score: personalityData.authenticity_score || 0.85,
    }

    return {
      quantum_compatibility: quantumCompatibility,
      personality_profile: personalityProfile,
      knot_compatibility: knotCompatibility,
      product_recommendations: productRecommendations,
      market_segment_metadata: {
        sample_size: personalityData.sample_size || 0,
        data_freshness: new Date().toISOString(),
        quantum_state_version: '1.0',
      },
    }
  }

  private async ensureSegmentExists(user_segment: any): Promise<void> {
    const { data: existing } = await this.supabase
      .from('market_segments')
      .select('segment_id')
      .eq('segment_id', user_segment.segment_id)
      .single()

    if (!existing) {
      await this.supabase.from('market_segments').insert({
        segment_id: user_segment.segment_id,
        segment_definition: user_segment,
        sample_size: 0,
      })
    }
  }

  private calculateQuantumCompatibility(
    personalityData: any,
    productState: any
  ): QuantumCompatibility {
    // Extract personality dimensions from aggregated data
    const personalityDimensions = personalityData
    const productAttributes = productState.attributes || {}

    // Calculate quantum inner product: |⟨ψ_user|ψ_product⟩|²
    // Simplified calculation for POC
    let compatibility = 0.0
    let dimensionCount = 0

    // Match personality dimensions with product attributes
    if (personalityDimensions.exploration_eagerness && productAttributes.novelty !== undefined) {
      const userValue = personalityDimensions.exploration_eagerness.value || 0.5
      const productValue = productAttributes.novelty || 0.5
      compatibility += 1 - Math.abs(userValue - productValue) // Inverse distance
      dimensionCount++
    }

    if (personalityDimensions.energy_preference && productAttributes.energy_level !== undefined) {
      const userValue = personalityDimensions.energy_preference.value || 0.5
      const productValue = productAttributes.energy_level || 0.5
      compatibility += 1 - Math.abs(userValue - productValue)
      dimensionCount++
    }

    if (personalityDimensions.community_orientation && productAttributes.community_oriented !== undefined) {
      const userValue = personalityDimensions.community_orientation.value || 0.5
      const productValue = productAttributes.community_oriented || 0.5
      compatibility += 1 - Math.abs(userValue - productValue)
      dimensionCount++
    }

    // Average compatibility across matched dimensions
    const score = dimensionCount > 0 ? compatibility / dimensionCount : 0.5

    // Square the result (quantum probability)
    const quantumScore = score * score

    return {
      score: Math.max(0, Math.min(1, quantumScore)),
      interpretation: quantumScore > 0.8 ? 'High compatibility' :
                      quantumScore > 0.6 ? 'Moderate compatibility' :
                      'Low compatibility',
      confidence: 0.84,
      formula: `|⟨ψ_user|ψ_product⟩|² = ${quantumScore.toFixed(3)}`,
    }
  }

  private async calculateKnotCompatibility(
    user_segment: any,
    productState: any
  ): Promise<KnotCompatibility> {
    // Placeholder: Knot compatibility calculation
    // In production, this would use actual knot invariants from personality_profiles
    // For POC, we'll use a simplified calculation based on personality dimensions

    // Simplified knot compatibility based on topological similarity
    // In production: Use Jones polynomial, Alexander polynomial, etc.
    const jonesMatch = 0.84 // Placeholder
    const alexanderMatch = 0.79 // Placeholder
    const topologicalSimilarity = (jonesMatch + alexanderMatch) / 2

    return {
      score: topologicalSimilarity,
      jones_polynomial_match: jonesMatch,
      alexander_polynomial_match: alexanderMatch,
      topological_similarity: topologicalSimilarity,
      knot_type_match: 'similar',
      interpretation: 'High topological compatibility',
    }
  }

  private generateProductRecommendations(
    compatibility: QuantumCompatibility,
    personalityData: any,
    productState: any
  ): ProductRecommendations {
    // Generate high compatibility products (placeholder - would query actual products)
    const highCompatibility: HighCompatibilityProduct[] = [
      {
        product_id: 'product_123',
        compatibility_score: compatibility.score * 1.05, // Slightly higher
        reasoning: `Matches ${productState.style || 'style'} preference + quality focus + ${personalityData.archetype || 'personality'} alignment`,
      },
      {
        product_id: 'product_456',
        compatibility_score: compatibility.score * 0.95, // Slightly lower
        reasoning: `High community orientation + sustainability focus`,
      },
    ]

    // Calculate compatibility breakdown
    const breakdown: CompatibilityBreakdown = {
      style_match: 0.92,
      price_match: 0.85,
      feature_match: 0.88,
      personality_match: compatibility.score,
    }

    return {
      high_compatibility: highCompatibility,
      compatibility_breakdown: breakdown,
    }
  }

  private formatPersonalityDimensions(data: any): Record<string, PersonalityDimension> {
    const dimensions: Record<string, PersonalityDimension> = {}

    // Extract dimension data (excluding metadata fields)
    const dimensionFields = [
      'exploration_eagerness',
      'community_orientation',
      'authenticity_preference',
      'social_discovery_style',
      'temporal_flexibility',
      'location_adventurousness',
      'curation_tendency',
      'trust_network_reliance',
      'energy_preference',
      'novelty_seeking',
      'value_orientation',
      'crowd_tolerance',
    ]

    for (const field of dimensionFields) {
      if (data[field]) {
        dimensions[field] = {
          value: data[field].value || 0.5,
          interpretation: this.getDimensionInterpretation(field, data[field].value),
          std_dev: data[field].std_dev || 0.15,
          percentiles: data[field].percentiles || {
            p25: 0.4,
            p50: 0.5,
            p75: 0.6,
          },
        }
      }
    }

    return dimensions
  }

  private getDimensionInterpretation(dimension: string, value: number): string {
    const interpretations: Record<string, (v: number) => string> = {
      exploration_eagerness: (v) => v > 0.7 ? 'High exploration eagerness' : v > 0.4 ? 'Moderate exploration' : 'Prefers familiar places',
      value_orientation: (v) => v > 0.7 ? 'Quality over price' : v > 0.4 ? 'Balanced value' : 'Price sensitive',
      community_orientation: (v) => v > 0.7 ? 'High community focus' : v > 0.4 ? 'Moderate community' : 'Solo preference',
      energy_preference: (v) => v > 0.7 ? 'High energy preference' : v > 0.4 ? 'Moderate energy' : 'Low energy preference',
      novelty_seeking: (v) => v > 0.7 ? 'High novelty seeking' : v > 0.4 ? 'Moderate novelty' : 'Prefers familiar',
    }

    return interpretations[dimension]?.(value) || 'Moderate preference'
  }

  private getDefaultPersonalityData(user_segment: any, productState: any): QuantumPersonalityData {
    // Return default data when actual data is not available
    const defaultCompatibility = 0.75 // Default compatibility score
    
    return {
      quantum_compatibility: {
        score: defaultCompatibility,
        interpretation: 'High compatibility (default estimate)',
        confidence: 0.75,
        formula: `|⟨ψ_user|ψ_product⟩|² = ${defaultCompatibility.toFixed(3)} (default)`,
      },
      personality_profile: {
        '12_dimensions': {
          exploration_eagerness: { value: 0.6, std_dev: 0.15, percentiles: { p25: 0.5, p50: 0.6, p75: 0.7 } },
          community_orientation: { value: 0.65, std_dev: 0.15, percentiles: { p25: 0.55, p50: 0.65, p75: 0.75 } },
          authenticity_preference: { value: 0.7, std_dev: 0.15, percentiles: { p25: 0.6, p50: 0.7, p75: 0.8 } },
          value_orientation: { value: 0.65, std_dev: 0.15, percentiles: { p25: 0.55, p50: 0.65, p75: 0.75 } },
        },
        archetype: 'Aggregate',
        authenticity_score: 0.85,
      },
      knot_compatibility: {
        score: 0.8,
        jones_polynomial_match: 0.84,
        alexander_polynomial_match: 0.79,
        topological_similarity: 0.815,
        knot_type_match: 'similar',
        interpretation: 'High topological compatibility (default estimate)',
      },
      product_recommendations: {
        high_compatibility: [
          {
            product_id: 'product_default_1',
            compatibility_score: defaultCompatibility * 1.05,
            reasoning: 'Default recommendation based on segment characteristics',
          },
        ],
        compatibility_breakdown: {
          style_match: 0.8,
          price_match: 0.75,
          feature_match: 0.85,
          personality_match: defaultCompatibility,
        },
      },
      market_segment_metadata: {
        sample_size: 0,
        data_freshness: new Date().toISOString(),
        quantum_state_version: '1.0',
      },
    }
  }
}
