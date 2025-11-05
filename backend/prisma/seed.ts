import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seed...');

  // Create recommendation templates
  const recommendations = [
    {
      slug: 'improve-sleep-quality',
      title: 'Improve Your Sleep Quality',
      category: 'Sleep',
      content: `
# Improve Your Sleep Quality

Poor sleep quality can significantly impact your overall health and wellbeing. Here are evidence-based strategies to enhance your sleep:

## Sleep Hygiene Protocols

- Maintain a consistent sleep schedule (same bedtime and wake time daily)
- Create a cool, dark, and quiet sleep environment (18-20°C optimal)
- Limit screen time 1-2 hours before bed (blue light disrupts melatonin)
- Avoid caffeine after 2 PM
- Exercise regularly, but not within 3 hours of bedtime
- Establish a relaxing bedtime routine (bath, reading, meditation)

## Herbal Support

**Consult a qualified herbalist before taking any supplements:**

- **Valerian root** (Valeriana officinalis): 300-600mg before bed
- **Passionflower** (Passiflora incarnata): Reduces anxiety and promotes relaxation
- **Chamomile tea**: 1-2 cups in the evening
- **Magnesium glycinate**: 200-400mg before bed (supports relaxation)

## When to Seek Help

If sleep issues persist for more than 3 weeks, consider consulting a herbalist, nutritionist, or sleep specialist.
      `,
      citations: [
        { title: 'Sleep hygiene practices', url: 'https://pubmed.ncbi.nlm.nih.gov/31408534/' },
        { title: 'Valerian for sleep quality', url: 'https://pubmed.ncbi.nlm.nih.gov/20347389/' },
        { title: 'Magnesium and sleep', url: 'https://pubmed.ncbi.nlm.nih.gov/23853635/' },
      ],
    },
    {
      slug: 'manage-stress-anxiety',
      title: 'Manage Stress and Anxiety',
      category: 'Stress',
      content: `
# Manage Stress and Anxiety

Chronic stress and anxiety can affect both your mental and physical health. Here are evidence-based approaches:

## Lifestyle Protocols

- **Deep breathing exercises**: Practice 4-7-8 breathing (inhale 4, hold 7, exhale 8)
- **Regular exercise**: 30 minutes of moderate activity 5x/week reduces cortisol
- **Mindfulness meditation**: 10-20 minutes daily can reduce anxiety by 30%
- **Limit alcohol and caffeine**: Both can exacerbate anxiety
- **Social connection**: Spend time with supportive friends and family
- **Sleep**: Prioritize 7-9 hours of quality sleep

## Herbal & Nutritional Support

**Consult a qualified practitioner before starting:**

- **Ashwagandha** (Withania somnifera): 300-500mg twice daily (adaptogen)
- **L-theanine**: 200mg daily (promotes calm alertness)
- **Rhodiola rosea**: 200-400mg daily (stress resilience)
- **Magnesium**: 200-400mg daily (nervous system support)
- **B-complex vitamins**: Support stress response

## Professional Support

If anxiety is interfering with daily life, consider working with a therapist, counselor, or herbalist.
      `,
      citations: [
        { title: 'Ashwagandha reduces stress', url: 'https://pubmed.ncbi.nlm.nih.gov/23439798/' },
        { title: 'L-theanine and anxiety', url: 'https://pubmed.ncbi.nlm.nih.gov/31758301/' },
        { title: 'Exercise reduces anxiety', url: 'https://pubmed.ncbi.nlm.nih.gov/32408214/' },
      ],
    },
    {
      slug: 'boost-energy-levels',
      title: 'Boost Your Energy Levels',
      category: 'Energy',
      content: `
# Boost Your Energy Levels

Low energy can stem from poor sleep, nutrition, stress, or underlying health issues. Address it holistically:

## Lifestyle Protocols

- **Prioritize sleep**: 7-9 hours nightly is essential
- **Stay hydrated**: Dehydration causes fatigue (aim for 2L water/day)
- **Eat regular meals**: Include protein, healthy fats, and complex carbs
- **Move regularly**: Even 10-minute walks boost energy
- **Manage stress**: Chronic stress depletes energy reserves
- **Limit sugar**: Avoid blood sugar crashes

## Nutritional Support

**Consult a qualified nutritionist or herbalist:**

- **Iron**: Essential for oxygen transport (if deficient)
- **Vitamin B12**: Critical for energy production
- **CoQ10**: 100-200mg daily (cellular energy)
- **Adaptogens**: Rhodiola, ginseng, cordyceps (support sustained energy)
- **Magnesium**: 200-400mg daily (energy metabolism)

## Root Causes to Investigate

- Thyroid function (underactive thyroid is common)
- Anemia or nutrient deficiencies
- Sleep disorders (sleep apnea)
- Chronic stress or burnout
      `,
      citations: [
        { title: 'CoQ10 and fatigue', url: 'https://pubmed.ncbi.nlm.nih.gov/24148965/' },
        { title: 'B12 and energy', url: 'https://pubmed.ncbi.nlm.nih.gov/23362493/' },
        { title: 'Rhodiola for fatigue', url: 'https://pubmed.ncbi.nlm.nih.gov/19016404/' },
      ],
    },
  ];

  console.log('Creating recommendation templates...');

  for (const rec of recommendations) {
    await prisma.recommendationTemplate.upsert({
      where: { slug: rec.slug },
      update: rec,
      create: rec,
    });
  }

  console.log(`✅ Created ${recommendations.length} recommendation templates`);

  console.log('✅ Database seeded successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Error seeding database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
