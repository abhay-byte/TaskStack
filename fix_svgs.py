import os
import xml.etree.ElementTree as ET

directory = 'assets/images'
svg_files = [f for f in os.listdir(directory) if f.endswith('.svg') and f.startswith('task_')]

def is_anim_class(class_str):
    if not class_str: return False
    return any(c.startswith('anim-') for c in class_str.split())

for filename in svg_files:
    filepath = os.path.join(directory, filename)
    with open(filepath, 'r') as f:
        content = f.read()
    
    # We will do a text-based search/replace because ElementTree strips out formatting/namespaces poorly
    # and we want to preserve the exact SVG structure without re-formatting.
    import re
    
    # regex to find <g class="anim-..." transform="translate(...)"> ... </g>
    # Since regex is risky with nested tags, let's just find the starting tag,
    # replace it with <g transform="..."><g class="anim-...">
    # and then we have to find the matching </g> to add an extra </g>.
    # Doing that via nested balanced parentheses in python regex is hard.
    # Instead, we will use a simple stack parser.
    
    def process_svg(svg_text):
        out = []
        i = 0
        tag_pattern = re.compile(r'<(/?)g([^>]*)>')
        # stack to keep track of tags that were doubled
        stack = []
        
        while i < len(svg_text):
            match = tag_pattern.search(svg_text, i)
            if not match:
                out.append(svg_text[i:])
                break
                
            out.append(svg_text[i:match.start()])
            is_closing = match.group(1) == '/'
            attrs = match.group(2)
            
            if is_closing:
                if stack and stack[-1]:
                    # This was a doubled tag
                    out.append('</g></g>')
                else:
                    out.append('</g>')
                if stack:
                    stack.pop()
            else:
                # Is it an opening <g> with both class="anim-..." and transform="..."?
                class_match = re.search(r'class="([^"]+)"', attrs)
                transform_match = re.search(r'transform="([^"]+)"', attrs)
                
                is_doubled = False
                if class_match and transform_match and is_anim_class(class_match.group(1)):
                    # Extract class and transform. We will remove transform from the inner tag.
                    t_val = transform_match.group(1)
                    
                    # Remove transform from the original attrs
                    clean_attrs = re.sub(r'\s*transform="[^"]+"', '', attrs)
                    
                    # Also replace any style="..." if it has animation properties? 
                    # Usually style doesn't have transform for positioning here, we just used transform attribute.
                    out.append(f'<g transform="{t_val}">\n        <g{clean_attrs}>')
                    is_doubled = True
                else:
                    out.append(match.group(0))
                
                stack.append(is_doubled)
            
            i = match.end()
            
        return "".join(out)
        
    new_content = process_svg(content)
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Fixed {filename}")
