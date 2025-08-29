#!/usr/bin/env python3
"""
高级f-string语法修复器
处理复杂的格式化表达式如 {var:.2f}, {var:,}, {var:,.0f} 等
"""

import re

def fix_advanced_fstring(content):
    """修复包含格式化表达式的f-string"""
    
    def replace_fstring_with_format(match):
        fstring_content = match.group(1)
        
        # 查找所有的{...}表达式
        expressions = re.findall(r'\{([^}]+)\}', fstring_content)
        
        # 处理每个表达式
        format_args = []
        format_string = fstring_content
        
        for i, expr in enumerate(expressions):
            if ':' in expr:
                # 分离变量和格式化
                var_part, format_part = expr.split(':', 1)
                format_args.append(var_part.strip())
                # 将{var:format}替换为{i:format}
                format_string = format_string.replace(f'{{{expr}}}', f'{{{i}:{format_part}}}')
            else:
                # 没有格式化，直接替换
                format_args.append(expr.strip())
                format_string = format_string.replace(f'{{{expr}}}', f'{{{i}}}')
        
        # 构造最终的.format()调用
        if format_args:
            args_str = ', '.join(format_args)
            return f'"{format_string}".format({args_str})'
        else:
            return f'"{format_string}"'
    
    # 替换f"..."模式
    content = re.sub(r'f"([^"]*)"', replace_fstring_with_format, content)
    content = re.sub(r"f'([^']*)'", replace_fstring_with_format, content)
    
    return content

def main():
    input_file = '/home/wuxia/projects/moomoo_custom_strategies/strategies/dca_dev_mixed.quant'
    output_file = '/home/wuxia/projects/moomoo_custom_strategies/strategies/dca_dev_moomoo_compatible.quant'
    
    # 读取原文件
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 修复f-string语法
    fixed_content = fix_advanced_fstring(content)
    
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