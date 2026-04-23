## update deploy
use jenkins to update deploy and docker to deploy to server
1. jenkins pull code from gitlab
2. jenkins 对接 sonarsourse 进行代码质量检查 www.sonarsource.com
3. jenkins 对接 sonatype 进行开源组件安全检查 www.sonatype.com
4. jenkins 对接 nexus 进行构建产物上传  www.sonatype.com/nexus/