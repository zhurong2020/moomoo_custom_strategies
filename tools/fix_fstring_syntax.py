#!/usr/bin/env python3
"""
修复f-string语法为Moomoo兼容格式
将f"..."语法转换为"...".format()语法
"""

import re
import sys

def fix_fstring(content):
    """将f-string语法转换为.format()语法"""
    
    # 简单的f-string模式: f"text {variable}"
    def replace_simple_fstring(match):
        fstring_content = match.group(1)
        
        # 提取变量名
        variables = re.findall(r'\{([^}]+)\}', fstring_content)
        
        # 替换{variable}为{0}, {1}, etc.
        format_string = fstring_content
        for i, var in enumerate(variables):
            format_string = format_string.replace(f'{{{var}}}', f'{{{i}}}')
        
        # 构造.format()调用
        if variables:
            vars_str = ', '.join(variables)
            return f'"{format_string}".format({vars_str})'
        else:
            return f'"{format_string}"'
    
    # 替换f-string模式
    # 匹配 f"..." 或 f'...'
    content = re.sub(r'f"([^"]*)"', replace_simple_fstring, content)
    content = re.sub(r"f'([^']*)'", replace_simple_fstring, content)
    
    return content

def main():
    input_file = '/home/wuxia/projects/moomoo_custom_strategies/strategies/dca_dev_mixed.quant'
    output_file = '/home/wuxia/projects/moomoo_custom_strategies/strategies/dca_dev_moomoo_compatible.quant'
    
    # 读取原文件
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 修复f-string语法
    fixed_content = fix_fstring(content)
    
    # 写入新文件
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(fixed_content)
    
    print(f"✅ 已生成Moomoo兼容版本: {output_file}")
    
    # 统计替换数量
    original_fstrings = content.count('f"') + content.count("f'")
    fixed_fstrings = fixed_content.count('f"') + fixed_content.count("f'")
    
    print(f"📊 原文件f-string数量: {original_fstrings}")
    print(f"📊 修复后f-string数量: {fixed_fstrings}")
    print(f"📊 成功替换: {original_fstrings - fixed_fstrings}")

if __name__ == "__main__":
    main()