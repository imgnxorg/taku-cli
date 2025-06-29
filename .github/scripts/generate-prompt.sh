#!/bin/bash

# Generate customized help prompt
# Usage: ./generate-prompt.sh [technical|philosophical|comprehensive] [show-examples|hide-examples]

FOCUS=${1:-comprehensive}
EXAMPLES=${2:-show-examples}

cat >../prompts/"${FOCUS}".prompt.md <<'EOF'
# Content Review Prompt

## What to Analyze

Please review the current file for the following aspects:

EOF

if [[ "$FOCUS" == "technical" || "$FOCUS" == "comprehensive" ]]; then
    cat >>../prompts/"${FOCUS}".prompt.md <<'EOF'
### 📝 **Technical Quality**
- Are there formatting issues or markdown syntax problems?
- Is the structure clear and well-organized?
- Are there any typos or grammatical errors?

### 🎨 **Style & Readability**
- Is the writing style engaging and appropriate for the content?
- Does it flow well and maintain reader interest?
- Is the tone consistent with the philosophical nature of this project?
- Is the content accessible to high school graduates while maintaining intellectual depth?

EOF
fi

if [[ "$FOCUS" == "philosophical" || "$FOCUS" == "comprehensive" ]]; then
    cat >>../prompts/"${FOCUS}".prompt.md <<'EOF'
### 💡 **Content Depth**
- Are there gaps in reasoning or missing connections?
- Does it effectively explore the themes of illusion, insight, and meaning?
- Are the concepts clearly explained and well-developed?

### 🔮 **Philosophical Alignment**
- Does the content effectively explore paradox and tension between opposing ideas?
- How well does it embody the themes of illusion serving purpose, insight providing growth, and meaning causing closure?
- Does it maintain the delicate balance between understanding and mystery?
- Is there appropriate use of metaphor and symbolic thinking?

EOF
fi

cat >>../prompts/"${FOCUS}".prompt.md <<'EOF'
### ✨ **Overall Impact**
- Does the final product feel polished and "stylish"?
- Is there anything crucial I'm missing or should have addressed?
- What would elevate this from good to exceptional?

## Context
This is part of a philosophical exploration of paradox, magic, and meaning - particularly around how illusions serve purpose, provide insight, but lose magic when given fixed meaning.

## Delivery Format
EOF

if [[ "$EXAMPLES" == "show-examples" ]]; then
    cat >>../prompts/"${FOCUS}".prompt.md <<'EOF'

**Quality Scale Reference**:
- **5**: Exceptional - Professional quality, engaging, error-free, deeply insightful
- **4**: Strong - Well-executed with minor areas for improvement  
- **3**: Good - Solid foundation, some gaps or inconsistencies
- **2**: Developing - Basic structure present, needs significant work
- **1**: Needs work - Major issues with clarity, accuracy, or engagement

EOF
fi

cat >>../prompts/"${FOCUS}".prompt.md <<'EOF'
Please provide:
1. **Scoring**: Rate each category above on a 1-5 scale with brief justification
2. **Analysis**: Detailed feedback for each category
3. **Missing Elements**: Identify anything crucial that should be added to this prompt for future use
4. **Next Steps**: Suggest 2-3 specific actions to improve the content
EOF

echo "Generated prompt: ../prompts/${FOCUS}.prompt.md"
echo "Focus: $FOCUS | Examples: $EXAMPLES"
