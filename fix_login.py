with open('lib/screens/login_screen.dart', 'r') as f:
    lines = f.readlines()

# The error starts at line 105 (0-indexed 104) and ends at line 115 (0-indexed 114)
# Let's just find the index of "              // SafeArea for Content\n"
start_idx = -1
for i, line in enumerate(lines):
    if line.startswith("              // SafeArea for Content"):
        start_idx = i
        break

if start_idx != -1:
    end_idx = -1
    for i in range(start_idx, len(lines)):
        if "borderRadius: BorderRadius.circular(16)," in lines[i]:
            end_idx = i
            break
            
    if end_idx != -1:
        new_lines = lines[:start_idx]
        new_lines.append("              // SafeArea for Content\n")
        new_lines.append("              SafeArea(\n")
        new_lines.append("                child: CustomScrollView(\n")
        new_lines.append("                  slivers: [\n")
        new_lines.append("                    SliverFillRemaining(\n")
        new_lines.append("                      hasScrollBody: false,\n")
        new_lines.append("                      child: Column(\n")
        new_lines.append("                        children: [\n")
        new_lines.append("                          const SizedBox(height: 16),\n")
        new_lines.append("                          // Mobile Logo Overlay\n")
        new_lines.append("                          Center(\n")
        new_lines.append("                            child: Container(\n")
        new_lines.append("                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),\n")
        new_lines.append("                              decoration: BoxDecoration(\n")
        new_lines.append("                                color: Colors.white.withOpacity(0.95),\n")
        new_lines.extend(lines[end_idx:])
        
        # Now fix Spacer to Expanded
        spacer_idx = -1
        for i in range(len(new_lines)):
            if "const Spacer()," in new_lines[i]:
                spacer_idx = i
                break
                
        if spacer_idx != -1:
            new_lines[spacer_idx] = "                          const Expanded(child: SizedBox(height: 32)),\n"
            
        with open('lib/screens/login_screen.dart', 'w') as f:
            f.writelines(new_lines)
        print("Success")
    else:
        print("End not found")
else:
    print("Start not found")
